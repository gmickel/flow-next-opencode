import type { Hooks, PluginInput } from "@opencode-ai/plugin"
import fs from "fs"
import path from "path"

const STATE_DIR = "/tmp"

const DEFAULT_REVIEWER = "opencode-reviewer"

type CallInfo = {
  tool: string
  command?: string
  subagent_type?: string
}

type State = {
  chats_sent: number
  chat_send_succeeded: boolean
  opencode_review_succeeded: boolean
  last_verdict?: string
  flowctl_done_called: string[]
  calls: Record<string, CallInfo>
}

function isRalph() {
  return process.env.FLOW_RALPH === "1"
}

function statePath(sessionID: string) {
  return path.join(STATE_DIR, `ralph-guard-${sessionID}.json`)
}

function loadState(sessionID: string): State {
  const file = statePath(sessionID)
  if (fs.existsSync(file)) {
    try {
      const raw = JSON.parse(fs.readFileSync(file, "utf8"))
      return {
        chats_sent: raw.chats_sent ?? 0,
        chat_send_succeeded: raw.chat_send_succeeded ?? false,
        opencode_review_succeeded: raw.opencode_review_succeeded ?? false,
        last_verdict: raw.last_verdict,
        flowctl_done_called: Array.isArray(raw.flowctl_done_called) ? raw.flowctl_done_called : [],
        calls: raw.calls ?? {},
      }
    } catch {}
  }
  return {
    chats_sent: 0,
    chat_send_succeeded: false,
    opencode_review_succeeded: false,
    flowctl_done_called: [],
    calls: {},
  }
}

function saveState(sessionID: string, state: State) {
  fs.writeFileSync(statePath(sessionID), JSON.stringify(state))
}

function block(message: string): never {
  throw new Error(message)
}

function isReceiptWrite(command: string, receiptPath: string) {
  const dir = path.dirname(receiptPath)
  return (
    command.includes(receiptPath) ||
    new RegExp(`>\\s*['\"]?${dir.replace(/[.*+?^${}()|[\]\\]/g, "\\$&")}`).test(command) ||
    /cat\s*>\s*.*receipt/i.test(command) ||
    /receipts\/.*\.json/.test(command)
  )
}

export default async function (_input: PluginInput): Promise<Hooks> {
  const allowedReviewer = process.env.FLOW_RALPH_REVIEWER_AGENT || DEFAULT_REVIEWER
  return {
    "tool.execute.before": async (input, output) => {
      if (!isRalph()) return output

      const sessionID = input.sessionID
      const state = loadState(sessionID)
      const callID = input.callID

      if (input.tool === "bash") {
        const command = String(output.args?.command ?? "")
        state.calls[callID] = { tool: "bash", command }

        if (command.includes("chat-send")) {
          if (/chat-send.*--json/.test(command)) {
            block("BLOCKED: Do not use --json with chat-send. It suppresses the review text.")
          }
          if (command.includes("--new-chat") && state.chats_sent > 0) {
            block("BLOCKED: Do not use --new-chat for re-reviews. Stay in the same chat.")
          }
        }

        if (command.includes("rp-cli")) {
          block("BLOCKED: Do not call rp-cli directly. Use flowctl rp wrappers.")
        }

        if (command.includes("setup-review")) {
          if (!/--repo-root/.test(command)) {
            block("BLOCKED: setup-review requires --repo-root.")
          }
          if (!/--summary/.test(command)) {
            block("BLOCKED: setup-review requires --summary.")
          }
        }

        if (command.includes("select-add")) {
          if (!/--window/.test(command) || !/--tab/.test(command)) {
            block("BLOCKED: select-add requires --window and --tab.")
          }
        }

        if (/\bdone\b/.test(command) && (command.includes("flowctl") || command.includes("FLOWCTL"))) {
          if (!/--help|-h/.test(command)) {
            if (!/--evidence-json|--evidence/.test(command)) {
              block("BLOCKED: flowctl done requires --evidence-json.")
            }
            if (!/--summary-file|--summary/.test(command)) {
              block("BLOCKED: flowctl done requires --summary-file.")
            }
          }
        }

        const receiptPath = process.env.REVIEW_RECEIPT_PATH || ""
        if (receiptPath && isReceiptWrite(command, receiptPath)) {
          if (!state.chat_send_succeeded && !state.opencode_review_succeeded) {
            block(
              "BLOCKED: Cannot write receipt before review completes. Run review and receive verdict first.",
            )
          }
          if (!/"id"\s*:/.test(command) && !/\'id\'\s*:/.test(command)) {
            block("BLOCKED: Receipt JSON missing required id field. Copy the exact template.")
          }
          if (command.includes("impl_review")) {
            const match =
              command.match(/"id"\s*:\s*"([^"]+)"/) || command.match(/'id'\s*:\s*'([^']+)'/)
            const taskId = match?.[1]
            if (taskId && !state.flowctl_done_called.includes(taskId)) {
              block(`BLOCKED: Cannot write impl receipt for ${taskId} - flowctl done was not called.`)
            }
          }
        }
      }

      if (input.tool === "task") {
        const subagent = String(output.args?.subagent_type ?? "")
        state.calls[callID] = { tool: "task", subagent_type: subagent }
        if (subagent !== allowedReviewer) {
          block(
            `BLOCKED: Ralph mode only allows task tool for reviewer '${allowedReviewer}'. ` +
              "Use the skill tool (flow-next-plan-review / flow-next-work) and do NOT spawn generic tasks.",
          )
        }
      }

      saveState(sessionID, state)
      return output
    },

    "tool.execute.after": async (input, output) => {
      if (!isRalph()) return output

      const sessionID = input.sessionID
      const state = loadState(sessionID)
      const callID = input.callID
      const call = state.calls[callID]
      const outputText = String(output.output ?? "")

      if (input.tool === "bash" && call?.command) {
        const command = call.command

        if (command.includes("chat-send")) {
          const hasVerdict = /<verdict>(SHIP|NEEDS_WORK|MAJOR_RETHINK)<\/verdict>/.test(outputText)
          const hasChat = outputText.includes("Chat Send") && !outputText.includes('"chat": null')
          if (hasVerdict || hasChat) {
            state.chats_sent = (state.chats_sent || 0) + 1
            state.chat_send_succeeded = true
          }
          if (outputText.includes('"chat": null')) {
            state.chat_send_succeeded = false
          }
        }

        if (/\bdone\b/.test(command) && (command.includes("flowctl") || command.includes("FLOWCTL"))) {
          const match = command.match(/\bdone\s+([a-zA-Z0-9][a-zA-Z0-9._-]*)/)
          if (match) {
            const taskId = match[1]
            const exit = output.metadata?.exit
            if (exit === 0) {
              if (!state.flowctl_done_called.includes(taskId)) state.flowctl_done_called.push(taskId)
            }
          }
        }

        const receiptPath = process.env.REVIEW_RECEIPT_PATH || ""
        if (receiptPath && command.includes(receiptPath) && command.includes(">")) {
          state.chat_send_succeeded = false
          state.opencode_review_succeeded = false
        }
      }

      if (input.tool === "task" && call?.subagent_type === allowedReviewer) {
        const verdict = outputText.match(/<verdict>(SHIP|NEEDS_WORK|MAJOR_RETHINK)<\/verdict>/)
        if (verdict) {
          state.opencode_review_succeeded = true
          state.last_verdict = verdict[1]
        }
      }

      delete state.calls[callID]
      saveState(sessionID, state)
      return output
    },
  }
}
