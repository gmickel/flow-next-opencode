# Implementation Review Workflow

## Philosophy

The reviewer model only sees provided context. RepoPrompt's Builder discovers context you'd miss (rp backend). OpenCode uses the provided diff context (opencode backend).

---

## Phase 0: Backend Detection

**Run this first. Do not skip.**

**CRITICAL: flowctl is BUNDLED — NOT installed globally.** `which flowctl` will fail (expected). Always use:

```bash
set -e
ROOT="$(git rev-parse --show-toplevel)"
OPENCODE_DIR="$ROOT/.opencode"
FLOWCTL="$OPENCODE_DIR/bin/flowctl"
REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"

# Check available backends
HAVE_RP=$(which rp-cli >/dev/null 2>&1 && echo 1 || echo 0)

# Get configured backend (priority: env > config)
BACKEND="${FLOW_REVIEW_BACKEND:-}"
if [[ -z "$BACKEND" ]]; then
  BACKEND="$($FLOWCTL config get review.backend --json 2>/dev/null | jq -r '.value // empty' 2>/dev/null || echo "")"
fi

# Fallback to available (opencode preferred)
if [[ -z "$BACKEND" ]]; then
  if [[ "$HAVE_RP" == "1" ]]; then BACKEND="opencode"
  else BACKEND="opencode"; fi
fi

echo "Review backend: $BACKEND"
```

**If backend is "none"**: Skip review, inform user, and exit cleanly (no error).

**Then branch to backend-specific workflow below.**

---

## OpenCode Backend Workflow

Use when `BACKEND="opencode"`.

### Step 1: Identify changes

```bash
TASK_ID="${1:-}"
BASE_BRANCH="main"
RECEIPT_PATH="${REVIEW_RECEIPT_PATH:-/tmp/impl-review-receipt.json}"

BRANCH_NAME="$(git branch --show-current)"
COMMITS="$(git log main..HEAD --oneline 2>/dev/null || git log master..HEAD --oneline)"
FILES="$(git diff main..HEAD --name-only 2>/dev/null || git diff master..HEAD --name-only)"
DIFF_OUTPUT="$(git diff main..HEAD 2>/dev/null || git diff master..HEAD)"
```

### Step 2: Build review prompt

Include:
- Branch + base branch
- Commit list
- Changed files
- Diff output (trim if huge)
- Focus areas from arguments
- Review criteria (correctness, security, performance, tests, risks)
- Required verdict tag

### Step 3: Execute review (subagent)

Use the **task** tool with subagent_type `opencode-reviewer`. The reviewer must gather context itself via tools, including Flow task/epic specs.

**Task tool call** (example):
```json
{
  "description": "Impl review",
  "prompt": "You are the OpenCode reviewer. Review current branch vs main. Rules: no questions, no code changes, no TodoWrite. REQUIRED: set FLOWCTL to `.opencode/bin/flowctl`, then run `$FLOWCTL show <TASK_ID> --json` and `$FLOWCTL cat <TASK_ID>`. Then get epic id from task JSON and run `$FLOWCTL show <EPIC_ID> --json` and `$FLOWCTL cat <EPIC_ID>`. REQUIRED: run `git log main..HEAD --oneline` (fallback master), `git diff main..HEAD --stat`, `git diff main..HEAD`. Read any changed files needed for correctness. Then output issues grouped by severity and end with exactly one verdict tag: <verdict>SHIP</verdict> or <verdict>NEEDS_WORK</verdict> or <verdict>MAJOR_RETHINK</verdict>.",
  "subagent_type": "opencode-reviewer"
}
```

**After the task completes**:
- Parse `VERDICT` from the subagent output.
- Extract `session_id` from the `<task_metadata>` block (used for re-reviews).

If `VERDICT` is empty, output `<promise>RETRY</promise>` and stop.

### Step 4: Receipt

If `REVIEW_RECEIPT_PATH` set:

```bash
mkdir -p "$(dirname "$RECEIPT_PATH")"
ts="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
cat > "$RECEIPT_PATH" <<EOF
{"type":"impl_review","id":"$TASK_ID","mode":"opencode","verdict":"<VERDICT>","timestamp":"$ts"}
EOF
```

### Step 5: Handle Verdict

If `VERDICT=NEEDS_WORK`:
1. Parse issues from output
2. Fix code, commit, run tests
3. Re-run Step 3 **with the same task session_id** (pass `session_id` to the task tool)
4. Repeat until SHIP

---

## RepoPrompt Backend Workflow

Use when `BACKEND="rp"`.

### Atomic Setup Block

```bash
# Atomic: pick-window + builder
eval "$($FLOWCTL rp setup-review --repo-root \"$REPO_ROOT\" --summary \"Review implementation: <summary>\")"

# Verify we have W and T
if [[ -z "${W:-}" || -z "${T:-}" ]]; then
  echo "<promise>RETRY</promise>"
  exit 0
fi

echo "Setup complete: W=$W T=$T"
```

If this block fails, output `<promise>RETRY</promise>` and stop. Do not improvise.

---

## Phase 1: Identify Changes (RP)

```bash
git branch --show-current
git log main..HEAD --oneline 2>/dev/null || git log master..HEAD --oneline
git diff main..HEAD --name-only 2>/dev/null || git diff master..HEAD --name-only
```

---

## Phase 2: Augment Selection (RP)

```bash
# See what builder selected
$FLOWCTL rp select-get --window "$W" --tab "$T"

# Always add changed files
$FLOWCTL rp select-add --window "$W" --tab "$T" path/to/changed/files...
```

---

## Phase 3: Execute Review (RP)

### Build combined prompt

Get builder's handoff:
```bash
HANDOFF="$($FLOWCTL rp prompt-get --window "$W" --tab "$T")"
```

Write combined prompt:
```bash
cat > /tmp/review-prompt.md << 'EOF'
[PASTE HANDOFF HERE]

---

## IMPORTANT: File Contents
RepoPrompt includes the actual source code of selected files in a `<file_contents>` XML section at the end of this message. You MUST:
1. Locate the `<file_contents>` section
2. Read and analyze the actual source code within it
3. Base your review on the code, not summaries or descriptions

If you cannot find `<file_contents>`, ask for the files to be re-attached before proceeding.

## Review Focus
[USER'S FOCUS AREAS]

## Review Criteria

Conduct a John Carmack-level review:

1. **Correctness** - Logic bugs? Edge cases? Race conditions?
2. **Safety** - Security risks? Data leaks? Injection paths?
3. **Performance** - Hot paths? N+1s? Unnecessary work?
4. **Maintainability** - Readability? Complexity? Abstractions?
5. **Tests** - Coverage gaps? Missing failure cases?
6. **Observability** - Logging/metrics? Debuggability?

## Output Format

For each issue:
- **Severity**: Critical / Major / Minor / Nitpick
- **Location**: File + line or area
- **Problem**: What's wrong
- **Suggestion**: How to fix

**REQUIRED**: You MUST end your response with exactly one verdict tag. This is mandatory:
`<verdict>SHIP</verdict>` or `<verdict>NEEDS_WORK</verdict>` or `<verdict>MAJOR_RETHINK</verdict>`

Do NOT skip this tag. The automation depends on it.
EOF
```

### Send to RepoPrompt

```bash
$FLOWCTL rp chat-send --window "$W" --tab "$T" --message-file /tmp/review-prompt.md --new-chat --chat-name "Impl Review: [BRANCH]"
```

**WAIT** for response. Takes 1-5+ minutes.

---

## Phase 4: Receipt + Status (RP)

### Write receipt (if REVIEW_RECEIPT_PATH set)

```bash
if [[ -n "${REVIEW_RECEIPT_PATH:-}" ]]; then
  ts="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  mkdir -p "$(dirname "$REVIEW_RECEIPT_PATH")"
  cat > "$REVIEW_RECEIPT_PATH" <<EOF
{"type":"impl_review","id":"<TASK_ID>","mode":"rp","timestamp":"$ts"}
EOF
  echo "REVIEW_RECEIPT_WRITTEN: $REVIEW_RECEIPT_PATH"
fi
```

---

## Fix Loop (RP)

**CRITICAL: You MUST fix the code BEFORE re-reviewing. Never re-review without making changes.**

If verdict is NEEDS_WORK:

1. **Parse issues** - Extract ALL issues by severity (Critical → Major → Minor)
2. **Fix the code** - Address each issue in order
3. **Run tests/lints** - Verify fixes don't break anything
4. **Commit fixes** (MANDATORY before re-review):
   ```bash
   git add -A
   git commit -m "fix: address review feedback"
   ```
   **If you skip this and re-review without committing changes, reviewer will return NEEDS_WORK again.**

5. **Re-review with fix summary** (only AFTER step 4):

   **IMPORTANT**: Do NOT re-add files already in the selection. RepoPrompt auto-refreshes
   file contents on every message. Only use `select-add` for NEW files created during fixes:
   ```bash
   # Only if fixes created new files not in original selection
   if [[ -n "$NEW_FILES" ]]; then
     $FLOWCTL rp select-add --window "$W" --tab "$T" $NEW_FILES
   fi
   ```

   Then send re-review request (NO --new-chat, stay in same chat).

   **Keep this message minimal. Do NOT enumerate issues or reference file_contents - the reviewer already has context from the previous exchange.**

   ```bash
   cat > /tmp/re-review.md << 'EOF'
   All issues from your previous review have been addressed. Please verify the updated implementation and provide final verdict.

   **REQUIRED**: End with `<verdict>SHIP</verdict>` or `<verdict>NEEDS_WORK</verdict>` or `<verdict>MAJOR_RETHINK</verdict>`
   EOF

   $FLOWCTL rp chat-send --window "$W" --tab "$T" --message-file /tmp/re-review.md
   ```
6. **Repeat** until Ship

**Anti-pattern**: Re-adding already-selected files before re-review. RP auto-refreshes; re-adding can cause issues.

---

## Failure Recovery

If rp-cli fails or returns empty output, output `<promise>RETRY</promise>` and stop. Do not improvise.

---

## Forbidden

- Self-declaring SHIP without actual reviewer output
- Skipping `setup-review` for rp backend
- Starting a new chat for re-reviews (rp backend only)
- Missing changed files in RP selection
