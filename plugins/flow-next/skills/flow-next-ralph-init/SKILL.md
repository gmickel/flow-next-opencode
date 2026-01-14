---
name: flow-next-ralph-init
description: Scaffold repo-local Ralph autonomous harness under scripts/ralph/. Use when user runs /flow-next:ralph-init.
---

# Ralph init

Scaffold repo-local Ralph harness. Opt-in only.

## Rules

- Only create `scripts/ralph/` in the current repo.
- If `scripts/ralph/` already exists, stop and ask the user to remove it first.
- Copy templates from `templates/` into `scripts/ralph/`.
- Copy `flowctl` and `flowctl.py` from `${CLAUDE_PLUGIN_ROOT}/scripts/` into `scripts/ralph/`.
- Set executable bit on `scripts/ralph/ralph.sh`, `scripts/ralph/ralph_once.sh`, and `scripts/ralph/flowctl`.

## Workflow

1. Resolve repo root: `git rev-parse --show-toplevel`
2. Check `scripts/ralph/` does not exist.
3. Detect available review backends:
   ```bash
   HAVE_RP=$(which rp-cli >/dev/null 2>&1 && echo 1 || echo 0)
   HAVE_CODEX=$(which codex >/dev/null 2>&1 && echo 1 || echo 0)
   ```
4. Determine review backend:
   - If BOTH available, ask user (do NOT use AskUserQuestion tool):
     ```
     Both RepoPrompt and Codex available. Which review backend?
     a) RepoPrompt (macOS, visual builder)
     b) Codex CLI (cross-platform, GPT 5.2 High)

     (Reply: "a", "rp", "b", "codex", or just tell me)
     ```
     Wait for response. Default if empty/ambiguous: `rp`
   - If only rp-cli available: use `rp`
   - If only codex available: use `codex`
   - If neither available: use `none`
5. Write `scripts/ralph/config.env` with:
   - `PLAN_REVIEW=<chosen>` and `WORK_REVIEW=<chosen>`
   - replace `{{PLAN_REVIEW}}` and `{{WORK_REVIEW}}` placeholders in the template
6. Copy templates and flowctl files.
7. Print next steps (run from terminal, NOT inside Claude Code):
   - Edit `scripts/ralph/config.env` to customize settings
   - `./scripts/ralph/ralph_once.sh` (one iteration, observe)
   - `./scripts/ralph/ralph.sh` (full loop, AFK)
   - Uninstall: `rm -rf scripts/ralph/`
