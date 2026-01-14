---
name: flow-next
description: "Manage .flow/ tasks and epics. Triggers: 'show me my tasks', 'list epics', 'what tasks are there', 'add a task', 'create task', 'what's ready', 'task status', 'show fn-1'. NOT for /flow-next:plan or /flow-next:work."
---

# Flow-Next Task Management

Quick task operations in `.flow/`. For planning features use `/flow-next:plan`, for executing use `/flow-next:work`.

## Setup

**CRITICAL: flowctl is BUNDLED — NOT installed globally.** `which flowctl` will fail (expected). Always use:

```bash
FLOWCTL="${CLAUDE_PLUGIN_ROOT}/scripts/flowctl"
```

Then run commands with `$FLOWCTL <command>`.

**Discover all commands/options:**
```bash
$FLOWCTL --help
$FLOWCTL <command> --help   # e.g., $FLOWCTL task --help
```

## Quick Reference

```bash
# Check if .flow exists
$FLOWCTL detect --json

# Initialize (if needed)
$FLOWCTL init --json

# List everything (epics + tasks grouped)
$FLOWCTL list --json

# List all epics
$FLOWCTL epics --json

# List all tasks (or filter by epic/status)
$FLOWCTL tasks --json
$FLOWCTL tasks --epic fn-1 --json
$FLOWCTL tasks --status todo --json

# View epic with all tasks
$FLOWCTL show fn-1 --json
$FLOWCTL cat fn-1              # Spec markdown

# View single task
$FLOWCTL show fn-1.2 --json
$FLOWCTL cat fn-1.2            # Task spec

# What's ready to work on?
$FLOWCTL ready --epic fn-1 --json

# Create task under existing epic
$FLOWCTL task create --epic fn-1 --title "Fix bug X" --json

# Set task description (from file)
echo "Description here" > /tmp/desc.md
$FLOWCTL task set-description fn-1.2 --file /tmp/desc.md --json

# Set acceptance criteria (from file)
echo "- [ ] Criterion 1" > /tmp/accept.md
$FLOWCTL task set-acceptance fn-1.2 --file /tmp/accept.md --json

# Start working on task
$FLOWCTL start fn-1.2 --json

# Mark task done
echo "What was done" > /tmp/summary.md
echo '{"commits":["abc123"],"tests":["npm test"],"prs":[]}' > /tmp/evidence.json
$FLOWCTL done fn-1.2 --summary-file /tmp/summary.md --evidence-json /tmp/evidence.json --json

# Validate structure
$FLOWCTL validate --epic fn-1 --json
$FLOWCTL validate --all --json
```

## Common Patterns

### "Add a task for X"

1. Find relevant epic:
   ```bash
   # List all epics
   $FLOWCTL epics --json

   # Or show a specific epic to check its scope
   $FLOWCTL show fn-1 --json
   ```

2. Create task:
   ```bash
   $FLOWCTL task create --epic fn-N --title "Short title" --json
   ```

3. Add description:
   ```bash
   cat > /tmp/desc.md << 'EOF'
   **Bug/Feature:** Brief description

   **Details:**
   - Point 1
   - Point 2
   EOF
   $FLOWCTL task set-description fn-N.M --file /tmp/desc.md --json
   ```

4. Add acceptance:
   ```bash
   cat > /tmp/accept.md << 'EOF'
   - [ ] Criterion 1
   - [ ] Criterion 2
   EOF
   $FLOWCTL task set-acceptance fn-N.M --file /tmp/accept.md --json
   ```

### "What tasks are there?"

```bash
# All epics
$FLOWCTL epics --json

# All tasks
$FLOWCTL tasks --json

# Tasks for specific epic
$FLOWCTL tasks --epic fn-1 --json

# Ready tasks for an epic
$FLOWCTL ready --epic fn-1 --json
```

### "Show me task X"

```bash
$FLOWCTL show fn-1.2 --json   # Metadata
$FLOWCTL cat fn-1.2           # Full spec
```

### Create new epic (rare - usually via /flow-next:plan)

```bash
$FLOWCTL epic create --title "Epic title" --json
# Returns: {"success": true, "id": "fn-N", ...}
```

## ID Format

- Epic: `fn-N` (e.g., `fn-1`, `fn-42`)
- Task: `fn-N.M` (e.g., `fn-1.1`, `fn-42.7`)

## Notes

- Run `$FLOWCTL --help` to discover all commands and options
- All writes go through flowctl (don't edit JSON/MD files directly)
- `--json` flag gives machine-readable output
- For complex planning/execution, use `/flow-next:plan` and `/flow-next:work`
