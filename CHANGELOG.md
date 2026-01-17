# Changelog

## Unreleased

- Rename OpenCode skills to `flow-next-opencode-*` to avoid Claude skill collisions
- Thanks @gmickel for the contribution

## 0.2.3

- Canonicalize `.opencode/` (remove legacy plugin/sync paths)
- Docs moved to `docs/` with updated links
- Ralph receipts now require verdicts

## 0.2.1

- Add browser skill (standalone)

## 0.2.2

- flowctl stdin support + Windows-safe codex exec piping
- flowctl status output + artifact-file guards
- Ralph Windows hardening + watch filter updates
- Plan/interview flows: stdin + task set-spec efficiency
- Docs: flowctl commands (checkpoint/status/task reset) restored
- Sync/porting guardrails updated for OpenCode

## 0.2.0

- Ralph (autonomous loop) + opencode runner/reviewer config
- OpenCode review session reuse for re-reviews
- Ralph hooks + watch stream for tool calls
- Updated Ralph docs + OpenCode config notes
- Ralph run control (pause/resume/stop/status) + sentinel support
- flowctl task reset + epic add-dep/rm-dep

## 0.1.0

- initial release (OpenCode port)
