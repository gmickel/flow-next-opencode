---
name: flow-next:uninstall
description: Remove flow-next files from project
---

# Flow-Next Uninstall

Use `AskUserQuestion` to confirm:

**Question 1:** "Remove flow-next from this project?"
- "Yes, uninstall"
- "Cancel"

If cancel → stop.

**Question 2:** "Keep your .flow/ tasks and epics?"
- "Yes, keep tasks" → only remove .flow/bin/, .flow/usage.md
- "No, remove everything" → remove entire .flow/

## Execute removal

Run these bash commands as needed:

```bash
# If keeping tasks:
rm -rf .flow/bin .flow/usage.md

# If removing everything:
rm -rf .flow

# Always check for Ralph:
rm -rf scripts/ralph
```

For CLAUDE.md and AGENTS.md: if file exists, remove everything between `<!-- BEGIN FLOW-NEXT -->` and `<!-- END FLOW-NEXT -->` (inclusive).

## Report

```
Removed:
- .flow/bin/, .flow/usage.md (or entire .flow/)
- scripts/ralph/ (if existed)
- Flow-next sections from docs (if existed)
```
