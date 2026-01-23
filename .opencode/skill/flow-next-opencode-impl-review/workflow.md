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

### Step 3: Execute review via flowctl

Use the `flowctl opencode impl-review` command:

```bash
# Use bash tool timeout: 600000 (10 minutes) for review commands
$FLOWCTL opencode impl-review "$TASK_ID" --base "$BASE_BRANCH" --receipt "$RECEIPT_PATH"
# Output includes VERDICT=SHIP|NEEDS_WORK|MAJOR_RETHINK
```

Parse `VERDICT` from the command output.

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
3. Re-run (use bash timeout 600000): `$FLOWCTL opencode impl-review "$TASK_ID" --base "$BASE_BRANCH" --receipt "$RECEIPT_PATH"`
4. Repeat until SHIP

---

## RepoPrompt Backend Workflow

Use when `BACKEND="rp"`.

**Requires RepoPrompt 1.6.0+** for the builder review mode. Check version with `rp-cli --version`.

### Phase 1: Identify Changes (RP)

```bash
TASK_ID="${1:-}"
BRANCH="$(git branch --show-current)"

COMMITS="$(git log main..HEAD --oneline 2>/dev/null || git log master..HEAD --oneline)"
CHANGED_FILES="$(git diff main..HEAD --name-only 2>/dev/null || git diff master..HEAD --name-only)"
```

### Phase 2: Build Review Instructions (RP)

Build XML-structured instructions for the builder review mode:

```bash
cat > /tmp/review-instructions.txt << EOF
<task>Review changes on the current branch for correctness, simplicity, and potential issues.

Focus on:
- Correctness - Logic errors, spec compliance
- Simplicity - Over-engineering, unnecessary complexity
- Edge cases - Failure modes, boundary conditions
- Security - Injection, auth gaps

Only flag issues in the changed code - not pre-existing patterns.
</task>

<context>
Branch: $BRANCH
Commits:
$COMMITS

Changed files:
$CHANGED_FILES
$([ -n "$TASK_ID" ] && echo "Task: $TASK_ID")
</context>

<discovery_agent-guidelines>
Focus on directories containing the changed files. Include git diffs for the commits.
</discovery_agent-guidelines>
EOF
```

### Phase 3: Execute Review (RP)

Use `setup-review` with `--response-type review` (RP 1.6.0+). The builder's discovery agent automatically:
- Selects relevant files and git diffs
- Analyzes code with full codebase context
- Returns structured review findings

```bash
# Run builder review mode
REVIEW_OUTPUT=$($FLOWCTL rp setup-review \
  --repo-root "$REPO_ROOT" \
  --summary "$(cat /tmp/review-instructions.txt)" \
  --response-type review \
  --json)

# Parse output
W=$(echo "$REVIEW_OUTPUT" | jq -r '.window')
T=$(echo "$REVIEW_OUTPUT" | jq -r '.tab')
CHAT_ID=$(echo "$REVIEW_OUTPUT" | jq -r '.chat_id')
REVIEW_FINDINGS=$(echo "$REVIEW_OUTPUT" | jq -r '.review')

if [[ -z "$W" || -z "$T" ]]; then
  echo "<promise>RETRY</promise>"
  exit 0
fi

echo "Setup complete: W=$W T=$T CHAT_ID=$CHAT_ID"
echo "Review findings:"
echo "$REVIEW_FINDINGS"
```

The builder returns review findings but **not a verdict tag**. Request verdict via follow-up:

```bash
cat > /tmp/verdict-request.md << 'EOF'
Based on your review findings above, provide your final verdict.

**REQUIRED**: End with exactly one verdict tag:
`<verdict>SHIP</verdict>` or `<verdict>NEEDS_WORK</verdict>` or `<verdict>MAJOR_RETHINK</verdict>`
EOF

$FLOWCTL rp chat-send --window "$W" --tab "$T" \
  --message-file /tmp/verdict-request.md \
  --chat-id "$CHAT_ID" \
  --mode review
```

**WAIT** for response. Extract verdict from response.

### Phase 4: Receipt + Status (RP)

```bash
if [[ -n "${REVIEW_RECEIPT_PATH:-}" ]]; then
  ts="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  mkdir -p "$(dirname "$REVIEW_RECEIPT_PATH")"
  cat > "$REVIEW_RECEIPT_PATH" <<EOF
{"type":"impl_review","id":"$TASK_ID","mode":"rp","timestamp":"$ts","chat_id":"$CHAT_ID"}
EOF
  echo "REVIEW_RECEIPT_WRITTEN: $REVIEW_RECEIPT_PATH"
fi
```

If no verdict tag in response, output `<promise>RETRY</promise>` and stop.

---

## Fix Loop (RP)

**CRITICAL: You MUST fix the code BEFORE re-reviewing. Never re-review without making changes.**

**MAX ITERATIONS**: Limit fix+re-review cycles to **${MAX_REVIEW_ITERATIONS:-3}** iterations (default 3, configurable in Ralph's config.env). If still NEEDS_WORK after max rounds, output `<promise>RETRY</promise>` and stop — let the next Ralph iteration start fresh.

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

   $FLOWCTL rp chat-send --window "$W" --tab "$T" --message-file /tmp/re-review.md --chat-id "$CHAT_ID" --mode review
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
