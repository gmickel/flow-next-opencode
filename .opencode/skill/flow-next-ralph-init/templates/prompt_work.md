You are running one Ralph work iteration.

Inputs:
- TASK_ID={{TASK_ID}}
- BRANCH_MODE={{BRANCH_MODE_EFFECTIVE}}
- WORK_REVIEW={{WORK_REVIEW}}

Treat the following as the user's exact input to flow-next-work:
`{{TASK_ID}} --branch={{BRANCH_MODE_EFFECTIVE}} --review={{WORK_REVIEW}}`

## Steps (execute ALL in order)

**Step 1: Execute task**
- Call the skill tool: flow-next-work.
- Follow the workflow in the skill using the exact arguments above.
- Do NOT run /flow-next:* as shell commands.
- Do NOT improvise review prompts; use the skill's review flow.

**Step 2: Verify task done** (AFTER skill returns)
```bash
scripts/ralph/flowctl show {{TASK_ID}} --json
```
If status != `done`, output `<promise>RETRY</promise>` and stop.

**Step 3: Write impl receipt** (MANDATORY if WORK_REVIEW != none)
```bash
mkdir -p "$(dirname '{{REVIEW_RECEIPT_PATH}}')"
ts="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
cat > '{{REVIEW_RECEIPT_PATH}}' <<EOF
{"type":"impl_review","id":"{{TASK_ID}}","mode":"{{WORK_REVIEW}}","timestamp":"$ts"}
EOF
echo "Receipt written: {{REVIEW_RECEIPT_PATH}}"
```
**CRITICAL: Copy the command EXACTLY. The "id":"{{TASK_ID}}" field is REQUIRED.**
Ralph verifies receipts match this exact schema. Missing id = verification fails = forced retry.

**Step 4: Validate epic**
```bash
scripts/ralph/flowctl validate --epic $(echo {{TASK_ID}} | sed 's/\.[0-9]*$//') --json
```

**Step 5: On hard failure** → output `<promise>FAIL</promise>` and stop.

## Rules
- Must run `flowctl done` and verify task status is `done` before commit.
- Must `git add -A` (never list files).
- Do NOT use TodoWrite.

Do NOT output `<promise>COMPLETE</promise>` in this prompt.
