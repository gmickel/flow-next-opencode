You are running one Ralph plan gate iteration.

Inputs:
- EPIC_ID={{EPIC_ID}}
- PLAN_REVIEW={{PLAN_REVIEW}}
- REQUIRE_PLAN_REVIEW={{REQUIRE_PLAN_REVIEW}}

Treat the following as the user's exact input to flow-next-opencode-plan-review:
`{{EPIC_ID}} --review={{PLAN_REVIEW}}`

Steps:
1) Re-anchor:
   - scripts/ralph/flowctl show {{EPIC_ID}} --json
   - scripts/ralph/flowctl cat {{EPIC_ID}}
   - git status
   - git log -10 --oneline

Ralph mode rules (must follow):
- If PLAN_REVIEW=rp: use `flowctl rp` wrappers (setup-review, select-add, prompt-get, chat-send).
- If PLAN_REVIEW=opencode: use `scripts/ralph/flowctl opencode plan-review` command.
- Write receipt via bash heredoc (no Write tool) if REVIEW_RECEIPT_PATH is set.
- Do NOT run /flow-next:* as shell commands.
- If any rule is violated, output `<promise>RETRY</promise>` and stop.

2) Plan review gate:
   - Call the skill tool: flow-next-opencode-plan-review.
   - Follow the workflow in the skill using the exact arguments above.
   - Do NOT stop after loading the skill.
   - For opencode: run `flowctl opencode plan-review` and require `<verdict>` tag.
   - For rp: use flowctl rp wrappers (no --json, no --new-chat on re-review).
   - For export: follow export flow in skill.
   - If PLAN_REVIEW=none:
     - If REQUIRE_PLAN_REVIEW=1: output `<promise>RETRY</promise>` and stop.
     - Else: set ship and stop:
       `scripts/ralph/flowctl epic set-plan-review-status {{EPIC_ID}} --status ship --json`

3) The skill will loop internally until `<verdict>SHIP</verdict>`:
   - First review uses `--new-chat`
   - If NEEDS_WORK: skill fixes plan, re-reviews in SAME chat (no --new-chat)
   - Repeats until SHIP
   - Only returns to Ralph after SHIP or MAJOR_RETHINK

4) IMMEDIATELY after SHIP verdict, write receipt (for any review mode != none):
   ```bash
   mkdir -p "$(dirname '{{REVIEW_RECEIPT_PATH}}')"
   ts="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
   cat > '{{REVIEW_RECEIPT_PATH}}' <<EOF
   {"type":"plan_review","id":"{{EPIC_ID}}","mode":"{{PLAN_REVIEW}}","verdict":"SHIP","timestamp":"$ts","iteration":{{RALPH_ITERATION}}}
   EOF
   ```
   **CRITICAL: Copy EXACTLY. The "id":"{{EPIC_ID}}" field is REQUIRED.**
   Missing id = verification fails = forced retry.

5) After SHIP:
   - `scripts/ralph/flowctl epic set-plan-review-status {{EPIC_ID}} --status ship --json`
   - stop (do NOT output promise tag)

6) If MAJOR_RETHINK (rare):
   - `scripts/ralph/flowctl epic set-plan-review-status {{EPIC_ID}} --status needs_work --json`
   - output `<promise>FAIL</promise>` and stop

7) On hard failure, output `<promise>FAIL</promise>` and stop.

Do NOT output `<promise>COMPLETE</promise>` in this prompt.
