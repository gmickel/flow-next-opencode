# Flow Plan Steps

**IMPORTANT**: Steps 1-3 (research, gap analysis, depth) ALWAYS run regardless of input type.

**CRITICAL**: If you are about to create:
- a markdown TODO list,
- a task list outside `.flow/`,
- or any plan files outside `.flow/`,

**STOP** and instead:
- create/update tasks in `.flow/` using `flowctl`,
- record details in the epic/task spec markdown.

## Success criteria

- Plan references existing files/patterns with line refs
- Reuse points are explicit (centralized code called out)
- Acceptance checks are testable
- Tasks are small enough for one `/flow-next:work` iteration (split if not)
- Open questions are listed

## Step 0: Initialize .flow

**CRITICAL: flowctl is BUNDLED — NOT installed globally.** `which flowctl` will fail (expected). Always use:

```bash
# Get flowctl path
FLOWCTL="${CLAUDE_PLUGIN_ROOT}/scripts/flowctl"

# Ensure .flow exists
$FLOWCTL init --json
```

## Step 1: Fast research (parallel)

**If input is a Flow ID** (fn-N or fn-N.M): First fetch it with `$FLOWCTL show <id> --json` and `$FLOWCTL cat <id>` to get the request context.

**Check if memory is enabled:**
```bash
$FLOWCTL config get memory.enabled --json
```

**Based on user's choice in SKILL.md setup:**

**If user chose context-scout (RepoPrompt)**:
Run these subagents in parallel using the Task tool:
- Task flow-next:context-scout(<request>) - uses RepoPrompt builder for AI-powered file discovery
- Task flow-next:practice-scout(<request>)
- Task flow-next:docs-scout(<request>)
- Task flow-next:memory-scout(<request>) - **only if memory.enabled is true**

**If user chose repo-scout (default/faster)** OR rp-cli unavailable:
Run these subagents in parallel using the Task tool:
- Task flow-next:repo-scout(<request>) - uses standard Grep/Glob/Read
- Task flow-next:practice-scout(<request>)
- Task flow-next:docs-scout(<request>)
- Task flow-next:memory-scout(<request>) - **only if memory.enabled is true**

Must capture:
- File paths + line refs
- Existing centralized code to reuse
- Similar patterns / prior work
- External docs links
- Project conventions (CLAUDE.md, CONTRIBUTING, etc)
- Architecture patterns and data flow (especially with context-scout)

## Step 2: Flow gap check

Run the gap analyst subagent:
- Task flow-next:flow-gap-analyst(<request>, research_findings)

Fold gaps + questions into the plan.

## Step 3: Pick depth

Default to short unless complexity demands more.

**SHORT** (bugs, small changes)
- Problem or goal
- Acceptance checks
- Key context

**STANDARD** (most features)
- Overview + scope
- Approach
- Risks / dependencies
- Acceptance checks
- Test notes
- References

**DEEP** (large/critical)
- Detailed phases
- Alternatives considered
- Non-functional targets
- Rollout/rollback
- Docs + metrics
- Risks + mitigations

## Step 4: Write to .flow

**Route A - Input was an existing Flow ID**:

1. If epic ID (fn-N):
   - Write a temp file with the updated plan spec
   - `$FLOWCTL epic set-plan <id> --file <temp-md> --json`
   - Create/update child tasks as needed

2. If task ID (fn-N.M):
   - Write temp file for description
   - `$FLOWCTL task set-description <id> --file <temp-md> --json`
   - Write temp file for acceptance
   - `$FLOWCTL task set-acceptance <id> --file <temp-md> --json`

**Route B - Input was text (new idea)**:

1. Create epic:
   ```bash
   $FLOWCTL epic create --title "<Short title>" --json
   ```
   This returns the epic ID (e.g., fn-1).

2. Set epic branch_name (deterministic):
   - Default: `fn-N` (use epic ID)
   ```bash
   $FLOWCTL epic set-branch <epic-id> --branch "<epic-id>" --json
   ```
   - If user specified a branch, use that instead.

3. Write epic spec:
   - Create a temp file with the full plan/spec content
   - Include: Overview, Scope, Approach, Quick commands (REQUIRED - at least one smoke test command), Acceptance, References
   - `$FLOWCTL epic set-plan <epic-id> --file <temp-md> --json`

4. Create child tasks:
   ```bash
   # For each task:
   $FLOWCTL task create --epic <epic-id> --title "<Task title>" --json
   ```

5. Write task specs:
   - For each task, write description and acceptance to temp files
   - `$FLOWCTL task set-description <task-id> --file <temp-md> --json`
   - `$FLOWCTL task set-acceptance <task-id> --file <temp-md> --json`

6. Add dependencies:
   ```bash
   # If task B depends on task A:
   $FLOWCTL dep add <task-B-id> <task-A-id> --json
   ```

7. Output current state:
   ```bash
   $FLOWCTL show <epic-id> --json
   $FLOWCTL cat <epic-id>
   ```

## Step 5: Validate

```bash
$FLOWCTL validate --epic <epic-id> --json
```

Fix any errors before proceeding.

## Step 6: Review (if chosen at start)

If user chose "Yes" to review in SKILL.md setup question:
1. Invoke `/flow-next:plan-review` with the epic ID
2. If review returns "Needs Work" or "Major Rethink":
   - **Re-anchor EVERY iteration** (do not skip):
     ```bash
     $FLOWCTL show <epic-id> --json
     $FLOWCTL cat <epic-id>
     ```
   - **Immediately fix the issues** (do NOT ask for confirmation — user already consented)
   - Re-run `/flow-next:plan-review`
3. Repeat until review returns "Ship"

**No human gates here** — the review-fix-review loop is fully automated.

**Why re-anchor every iteration?** Per Anthropic's long-running agent guidance: context compresses, you forget details. Re-read before each fix pass.

## Step 7: Offer next step

Show the epic summary and suggest next actions:

```
Epic created: fn-N with M tasks.

Next:
1) Start work: `/flow-next:work fn-N`
2) Refine via interview: `/flow-next:interview fn-N`
3) Review the plan: `/flow-next:plan-review fn-N`
```
