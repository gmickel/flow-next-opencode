---
name: flow-next-opencode-plan
description: Create structured build plans from feature requests or Flow IDs. Use when planning features or designing implementation. Triggers on /flow-next:plan with text descriptions or Flow IDs (fn-1, fn-1.2).
---

# Flow plan

Turn a rough idea into an epic with tasks in `.flow/`. This skill does not write code.

Follow this skill and linked workflows exactly. Deviations cause drift, bad gates, retries, and user frustration.

**IMPORTANT**: This plugin uses `.flow/` for ALL task tracking. Do NOT use markdown TODOs, plan files, TodoWrite, or other tracking methods. All task state must be read and written via `flowctl`.

**CRITICAL: flowctl is BUNDLED — NOT installed globally.** `which flowctl` will fail (expected). Always use:
```bash
ROOT="$(git rev-parse --show-toplevel)"
OPENCODE_DIR="$ROOT/.opencode"
FLOWCTL="$OPENCODE_DIR/bin/flowctl"
$FLOWCTL <command>
```

**Role**: product-minded planner with strong repo awareness.
**Goal**: produce an epic with tasks that match existing conventions and reuse points.
**Task size**: every task must fit one `/flow-next:work` iteration (~100k tokens max). If it won't, split it.

## The Golden Rule: No Implementation Code

**Plans are specs, not implementations.** Do NOT write the code that will be implemented.

### Code IS allowed:
- **Signatures/interfaces** (what, not how): `function validate(input: string): Result`
- **Patterns from this repo** (with file:line ref): "Follow pattern at `src/auth.ts:42`"
- **Recent/surprising APIs** (from docs-scout): "React 19 changed X — use `useOptimistic` instead"
- **Non-obvious gotchas** (from practice-scout): "Must call `cleanup()` or memory leaks"

### Code is FORBIDDEN:
- Complete function implementations
- Full class/module bodies
- "Here's what you'll write" blocks
- Copy-paste ready snippets (>10 lines)

**Why:** Implementation happens in `/flow-next:work` with fresh context. Writing it here wastes tokens in planning, review, AND implementation — then causes drift when the implementer does it differently anyway.

## Input

Full request: $ARGUMENTS

Accepts:
- Feature/bug description in natural language
- Flow epic ID `fn-N` to refine existing epic
- Flow task ID `fn-N.M` to refine specific task
- Chained instructions like "then review with /flow-next:plan-review"

Examples:
- `/flow-next:plan Add OAuth login for users`
- `/flow-next:plan fn-1`
- `/flow-next:plan fn-1 then review via /flow-next:plan-review`

If empty, ask: "What should I plan? Give me the feature or bug in 1-5 sentences."

## FIRST: Parse Options or Ask Questions

Check available backends and configured preference:
```bash
HAVE_RP=0;
if command -v rp-cli >/dev/null 2>&1; then
  HAVE_RP=1;
elif [[ -x /opt/homebrew/bin/rp-cli || -x /usr/local/bin/rp-cli ]]; then
  HAVE_RP=1;
fi;

# Check configured backend (priority: env > config)
CONFIGURED_BACKEND="${FLOW_REVIEW_BACKEND:-}";
if [[ -z "$CONFIGURED_BACKEND" ]]; then
  CONFIGURED_BACKEND="$($FLOWCTL config get review.backend --json 2>/dev/null | jq -r '.value // empty')";
fi
```

**MUST RUN the detection command above** and use its result. Do **not** assume rp-cli is missing without running it.

### Option Parsing (skip questions if found in arguments)

Parse the arguments for these patterns. If found, use them and skip questions:

**Research approach** (only if rp-cli available):
- `--research=rp` or `--research rp` or "use rp" or "context-scout" or "use repoprompt" → context-scout
- `--research=grep` or `--research grep` or "use grep" or "repo-scout" or "fast" → repo-scout

**Review mode**:
- `--review=opencode` or "opencode review" or "use opencode" → OpenCode review (GPT-5.2, reasoning high)
- `--review=rp` or "review with rp" or "rp chat" or "repoprompt review" → RepoPrompt chat (via `flowctl rp chat-send`)
- `--review=export` or "export review" or "external llm" → export for external LLM
- `--review=none` or `--no-review` or "no review" or "skip review" → no review

### If options NOT found in arguments

**IMPORTANT**: Ask setup questions in **plain text only**. **Do NOT use the question tool.** This is required for voice dictation (e.g., "1a 2b").

**Plan depth** (parse from args or ask):
- `--depth=short` or "quick" or "minimal" → SHORT
- `--depth=standard` or "normal" → STANDARD
- `--depth=deep` or "comprehensive" or "detailed" → DEEP
- Default: SHORT (simpler is better)

**Skip review question if**: Ralph mode (`FLOW_RALPH=1`) OR backend already configured (`CONFIGURED_BACKEND` not empty). In these cases, only ask research question (if rp-cli available):

```
Quick setup: Use RepoPrompt for deeper context?
a) Yes, context-scout (slower, thorough)
b) No, repo-scout (faster)

(Reply: "a", "b", or just tell me)
(Tip: --depth=short|standard|deep, --review=rp|opencode|none)
```

If rp-cli not available, skip questions entirely and use defaults.

**Otherwise**, output questions based on available backends:

**If rp-cli available:**
```
Quick setup before planning:

1. **Plan depth** — How detailed?
   a) Short — problem, acceptance, key context only
   b) Standard (default) — + approach, risks, test notes
   c) Deep — + phases, alternatives, rollout plan

2. **Research** — Use RepoPrompt for deeper context?
   a) Yes, context-scout (slower, thorough)
   b) No, repo-scout (faster)

3. **Review** — Run Carmack-level review after?
   a) OpenCode review (GPT-5.2, reasoning high)
   b) RepoPrompt chat (macOS, visual builder)
   c) Export for external LLM (ChatGPT, Claude web)
   d) None (configure later)

(Reply: "1a 2b 3d", or just tell me naturally)
```

**If rp-cli not available:**
```
Quick setup before planning:

1. **Plan depth** — How detailed?
   a) Short — problem, acceptance, key context only
   b) Standard (default) — + approach, risks, test notes
   c) Deep — + phases, alternatives, rollout plan

2. **Review** — Run Carmack-level review after?
   a) Yes, OpenCode review (GPT-5.2, reasoning high)
   b) Yes, export for external LLM
   c) No

(Reply: "1a 2a", "1b 2c", or just tell me naturally)
```

Wait for response. Parse naturally — user may reply terse ("1a 2b") or ramble via voice.

**Defaults when empty/ambiguous:**
- Depth = `standard` (balanced detail)
- Research = `grep` (repo-scout)
- Review = configured backend if set, else `opencode`, else `rp` if available, else `none`

If rp-cli not available: skip research questions, use repo-scout, review defaults to `opencode` or `none` if disabled.

**Defaults when no review backend available:**
- Depth = `standard`
- Research = `grep`
- Review = `none`

## Workflow

Read [steps.md](steps.md) and follow each step in order. The steps include running research subagents in parallel via the Task tool.
If user chose review:
- Option 2a: run `/flow-next:plan-review` after Step 4, fix issues until it passes
- Option 2b: run `/flow-next:plan-review` with export mode after Step 4

## Output

All plans go into `.flow/`:
- Epic: `.flow/epics/fn-N.json` + `.flow/specs/fn-N.md`
- Tasks: `.flow/tasks/fn-N.M.json` + `.flow/tasks/fn-N.M.md`

**Never write plan files outside `.flow/`. Never use TodoWrite for task tracking.**

## Output rules

- Only create/update epics and tasks via flowctl
- No code changes
- No plan files outside `.flow/`
