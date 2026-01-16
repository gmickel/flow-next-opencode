---
name: flow-next-plan-review
description: Carmack-level plan review via RepoPrompt or OpenCode. Use when reviewing Flow epic specs or design docs. Triggers on /flow-next:plan-review.
---

# Plan Review Mode

**Read [workflow.md](workflow.md) for detailed phases and anti-patterns.**

Conduct a John Carmack-level review of epic plans.

**Role**: Code Review Coordinator (NOT the reviewer)
**Backends**: OpenCode (opencode) or RepoPrompt (rp)

**CRITICAL: flowctl is BUNDLED — NOT installed globally.** `which flowctl` will fail (expected). Always use:
```bash
ROOT="$(git rev-parse --show-toplevel)"
PLUGIN_ROOT="$ROOT/plugins/flow-next"
FLOWCTL="$PLUGIN_ROOT/scripts/flowctl"
```

## Backend Selection

**Priority** (first match wins):
1. `--review=rp|opencode|export|none` argument
2. `FLOW_REVIEW_BACKEND` env var (`rp`, `opencode`, `none`)
3. `.flow/config.json` → `review.backend`
4. Interactive prompt if rp-cli available (and not in Ralph mode)
5. Default: `opencode`

### Parse from arguments first

Check $ARGUMENTS for:
- `--review=rp` or `--review rp` → use rp
- `--review=opencode` or `--review opencode` → use opencode
- `--review=export` or `--review export` → use export
- `--review=none` or `--review none` → skip review

If found, use that backend and skip all other detection.

### Otherwise detect

```bash
# Check available backends
HAVE_RP=0;
if command -v rp-cli >/dev/null 2>&1; then
  HAVE_RP=1;
elif [[ -x /opt/homebrew/bin/rp-cli || -x /usr/local/bin/rp-cli ]]; then
  HAVE_RP=1;
fi;

# Get configured backend
BACKEND="${FLOW_REVIEW_BACKEND:-}";
if [[ -z "$BACKEND" ]]; then
  BACKEND="$($FLOWCTL config get review.backend 2>/dev/null | jq -r '.value // empty')";
fi
```

**MUST RUN the detection command above** and use its result. Do **not** assume rp-cli is missing without running it.

### If no backend configured and rp available

If `BACKEND` is empty AND `HAVE_RP=1`, AND not in Ralph mode (`FLOW_RALPH` not set):

Output this question as text:
```
Which review backend?
a) OpenCode review (GPT-5.2, reasoning high)
b) RepoPrompt (macOS, visual builder)

(Reply: "a", "opencode", "b", "rp", or just tell me)
```

**IMPORTANT**: Ask this in **plain text only**. **Do NOT use the question tool.**

Wait for response. Parse naturally.

**Default if empty/ambiguous**: `opencode`

### If only one available or in Ralph mode

```bash
# Fallback to available
if [[ -z "$BACKEND" ]]; then
  if [[ "$HAVE_RP" == "1" ]]; then BACKEND="opencode"
  else BACKEND="opencode"; fi
fi
```

## Critical Rules

**For rp backend:**
1. **DO NOT REVIEW THE PLAN YOURSELF** - you coordinate, RepoPrompt reviews
2. **MUST WAIT for actual RP response** - never simulate/skip the review
3. **MUST use `setup-review`** - handles window selection + builder atomically
4. **DO NOT add --json flag to chat-send** - it suppresses the review response
5. **Re-reviews MUST stay in SAME chat** - omit `--new-chat` after first review

**For opencode backend:**
1. Use `flowctl opencode plan-review` (deterministic CLI wrapper)
2. Parse verdict from `VERDICT` or JSON output
3. If `REVIEW_RECEIPT_PATH` set: flowctl writes receipt JSON with `mode: "opencode"`
4. Re-reviews: re-run the same command (no session_id reuse)

**For all backends:**
- If `REVIEW_RECEIPT_PATH` set: write receipt after review (any verdict)
- Any failure → output `<promise>RETRY</promise>` and stop

**FORBIDDEN**:
- Self-declaring SHIP without actual backend verdict
- Mixing backends mid-review (stick to one)
- Skipping review when backend is "none" without user consent

## Input

Arguments: $ARGUMENTS
Format: `<flow-epic-id> [focus areas]`

## Workflow

**See [workflow.md](workflow.md) for full details on each backend.**

```bash
ROOT="$(git rev-parse --show-toplevel)"
PLUGIN_ROOT="$ROOT/plugins/flow-next"
FLOWCTL="$PLUGIN_ROOT/scripts/flowctl"
REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
```

### Step 0: Detect Backend

Run backend detection from SKILL.md above. Then branch:

### OpenCode Backend

```bash
EPIC_ID="${1:-}"
RECEIPT_PATH="${REVIEW_RECEIPT_PATH:-/tmp/plan-review-receipt.json}"

# Gather plan content
PLAN_SUMMARY="$($FLOWCTL show "$EPIC_ID" --json)"
PLAN_SPEC="$($FLOWCTL cat "$EPIC_ID")"
```

Build a review prompt with:
- Plan summary + spec
- Focus areas from arguments
- Review criteria (completeness, feasibility, clarity, architecture, risks, scope, testability)
- Required verdict tag

Run review via flowctl:
```bash
$FLOWCTL opencode plan-review "$EPIC_ID" --receipt "$RECEIPT_PATH" --json
```
Parse verdict from JSON (`.verdict`).

On NEEDS_WORK: fix plan via `$FLOWCTL epic set-plan`, then re-run review (same backend).

Receipt is written by `flowctl opencode plan-review` when `--receipt` is provided.

### RepoPrompt Backend

```bash
# Step 1: Get plan content
$FLOWCTL show <id> --json
$FLOWCTL cat <id>

# Step 2: Atomic setup
eval "$($FLOWCTL rp setup-review --repo-root "$REPO_ROOT" --summary "Review plan for <EPIC_ID>: <summary>")"
# Outputs W=<window> T=<tab>. If fails → <promise>RETRY</promise>

# Step 3: Augment selection
$FLOWCTL rp select-add --window "$W" --tab "$T" .flow/specs/<epic-id>.md

# Step 4: Build and send review prompt (see workflow.md)
$FLOWCTL rp chat-send --window "$W" --tab "$T" --message-file /tmp/review-prompt.md --new-chat --chat-name "Plan Review: <EPIC_ID>"

# Step 5: Write receipt if REVIEW_RECEIPT_PATH set
# Step 6: Update status
$FLOWCTL epic set-plan-review-status <EPIC_ID> --status ship --json
```

## Fix Loop (INTERNAL - do not exit to Ralph)

If verdict is NEEDS_WORK, loop internally until SHIP:

1. **Parse issues** from reviewer feedback
2. **Fix plan** via `$FLOWCTL epic set-plan <EPIC_ID> --file /tmp/updated-plan.md`
3. **Re-review**:
   - **OpenCode**: re-run reviewer subagent with updated plan
   - **RP**: `$FLOWCTL rp chat-send --window "$W" --tab "$T" --message-file /tmp/re-review.md` (NO `--new-chat`)
4. **Repeat** until `<verdict>SHIP</verdict>`

**CRITICAL**: For RP, re-reviews must stay in the SAME chat so reviewer has context. Only use `--new-chat` on the FIRST review.
