---
name: flow-next-opencode-sync
description: Manually trigger plan-sync to update downstream task specs after implementation drift. Use when code changes outpace specs.
---

# Manual Plan-Sync

Manually trigger plan-sync to update downstream task specs.

**CRITICAL: flowctl is BUNDLED — NOT installed globally.** Always use:
```bash
ROOT="$(git rev-parse --show-toplevel)"
OPENCODE_DIR="$ROOT/.opencode"
FLOWCTL="$OPENCODE_DIR/bin/flowctl"
```

## Input

Arguments: $ARGUMENTS
Format: `<id> [--dry-run]`

- `<id>` - task ID (fn-N.M) or epic ID (fn-N)
- `--dry-run` - show changes without writing

## Workflow

### Step 1: Parse Arguments

```bash
ROOT="$(git rev-parse --show-toplevel)"
OPENCODE_DIR="$ROOT/.opencode"
FLOWCTL="$OPENCODE_DIR/bin/flowctl"
```

Parse $ARGUMENTS for:
- First positional arg = `ID`
- `--dry-run` flag = `DRY_RUN` (true/false)

**Validate ID format:**
- Must start with `fn-`
- If no ID: "Usage: /flow-next:sync <id> [--dry-run]"
- If invalid: "Invalid ID format. Use fn-N (epic) or fn-N.M (task)."

Detect ID type:
- Contains `.` (e.g., fn-1.2) → task ID
- No `.` (e.g., fn-1) → epic ID

### Step 2: Validate Environment

```bash
test -d .flow || { echo "No .flow/ found. Run flowctl init first."; exit 1; }
```

If `.flow/` missing, output error and stop.

### Step 3: Validate ID Exists

```bash
$FLOWCTL show <ID> --json
```

If fails:
- Task: "Task <id> not found. Run `flowctl list` to see available."
- Epic: "Epic <id> not found. Run `flowctl epics` to see available."

Stop on failure.

### Step 4: Find Downstream Tasks

**For task ID input:**
```bash
# Extract epic from task ID
EPIC=$(echo "<task-id>" | sed 's/\.[0-9]*$//')

# Get all tasks in epic
$FLOWCTL tasks --epic "$EPIC" --json
```

Filter to `status: todo` or `status: blocked`. Exclude source task.

**For epic ID input:**
```bash
$FLOWCTL tasks --epic "<epic-id>" --json
```

1. Find **source task** (agent requires `COMPLETED_TASK_ID`):
   - Prefer most recently updated task with `status: done`
   - Else: most recently updated with `status: in_progress`
   - Else: error "No completed or in-progress tasks to sync from."

2. Filter remaining to `status: todo` or `status: blocked` (downstream).

**If no downstream tasks:**
```
No downstream tasks to sync (all done or none exist).
```
Stop (success).

### Step 5: Spawn Plan-Sync Agent

Build context and spawn via Task tool:

```
Sync task specs from <source> to downstream tasks.

COMPLETED_TASK_ID: <source task id>
FLOWCTL: $OPENCODE_DIR/bin/flowctl
EPIC_ID: <epic id>
DOWNSTREAM_TASK_IDS: <comma-separated list>
DRY_RUN: <true|false>

<if DRY_RUN>
DRY RUN MODE: Report changes but do NOT edit files.
</if>
```

Use Task tool with `subagent_type: flow-next:plan-sync`

### Step 6: Report Results

**Normal mode:**
```
Plan-sync: <source> -> downstream tasks

Scanned: N tasks (<list>)
<agent summary>
```

**Dry-run mode:**
```
Plan-sync: <source> -> downstream tasks (DRY RUN)

<agent summary>

No files modified.
```

## Error Messages

| Case | Message |
|------|---------|
| No ID | "Usage: /flow-next:sync <id> [--dry-run]" |
| No `.flow/` | "No .flow/ found. Run `flowctl init` first." |
| Invalid format | "Invalid ID format. Use fn-N (epic) or fn-N.M (task)." |
| Task not found | "Task <id> not found. Run `flowctl list` to see available." |
| Epic not found | "Epic <id> not found. Run `flowctl epics` to see available." |
| No source | "No completed or in-progress tasks to sync from." |
| No downstream | "No downstream tasks to sync (all done or none exist)." |

## Rules

- **Ignores config** - `planSync.enabled` is for auto-trigger; manual always runs
- **Any source status** - source can be todo, in_progress, done, or blocked
- **Includes blocked** - downstream includes both `todo` and `blocked` tasks
- **Reuses agent** - spawns plan-sync agent, no duplication
