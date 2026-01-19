---
name: flow-next-opencode-ralph-init
description: Scaffold repo-local Ralph autonomous harness under scripts/ralph/. Use when user runs /flow-next:ralph-init.
---

# Ralph init

Scaffold repo-local Ralph harness. Opt-in only.

## Rules

- Only create/update `scripts/ralph/` in the current repo.
- If `scripts/ralph/` already exists, offer to update (preserves config.env).
- Copy templates from `.opencode/skill/flow-next-opencode-ralph-init/templates/` into `scripts/ralph/`.
- Copy `flowctl` and `flowctl.py` from `$OPENCODE_DIR/bin/` into `scripts/ralph/`.
- Set executable bit on `scripts/ralph/ralph.sh`, `scripts/ralph/ralph_once.sh`, and `scripts/ralph/flowctl`.

## Workflow

1. Resolve repo root and OpenCode dir:
   ```bash
   ROOT="$(git rev-parse --show-toplevel)"
   OPENCODE_DIR="$ROOT/.opencode"
   TEMPLATE_DIR="$ROOT/.opencode/skill/flow-next-opencode-ralph-init/templates"
   ```

2. Check if `scripts/ralph/` exists:
   - If exists: ask "Update existing Ralph setup? (preserves config.env and runs/) [y/n]"
     - If no: stop
     - If yes: set UPDATE_MODE=1
   - If not exists: set UPDATE_MODE=0

3. Detect available review backends (skip if UPDATE_MODE=1):
   ```bash
HAVE_RP=0;
if command -v rp-cli >/dev/null 2>&1; then
  HAVE_RP=1;
elif [[ -x /opt/homebrew/bin/rp-cli || -x /usr/local/bin/rp-cli ]]; then
  HAVE_RP=1;
fi
   ```
4. Determine review backend (skip if UPDATE_MODE=1):
   - If rp-cli available, ask user:
     ```
     Which review backend?
     a) OpenCode (GPT‑5.2 High)
     b) RepoPrompt (macOS, visual builder)

     (Reply: "a", "opencode", "b", "rp", or just tell me)
     ```
     Wait for response. Default if empty/ambiguous: `opencode`
   - If only rp-cli available and user chooses rp: use `rp`
   - Otherwise: use `opencode`
   - If neither available and user requests none: use `none`

5. Copy files using bash (MUST use cp, NOT Write tool):

   **If UPDATE_MODE=1 (updating):**
   ```bash
   # Backup config.env
   cp scripts/ralph/config.env /tmp/ralph-config-backup.env

   # Update templates (preserves runs/)
   cp "$TEMPLATE_DIR/ralph.sh" scripts/ralph/
   cp "$TEMPLATE_DIR/ralph_once.sh" scripts/ralph/
   cp "$TEMPLATE_DIR/prompt_plan.md" scripts/ralph/
   cp "$TEMPLATE_DIR/prompt_work.md" scripts/ralph/
   cp "$TEMPLATE_DIR/watch-filter.py" scripts/ralph/
   cp "$OPENCODE_DIR/bin/flowctl" "$OPENCODE_DIR/bin/flowctl.py" scripts/ralph/
   chmod +x scripts/ralph/ralph.sh scripts/ralph/ralph_once.sh scripts/ralph/flowctl

   # Restore config.env
   cp /tmp/ralph-config-backup.env scripts/ralph/config.env
   ```

   **If UPDATE_MODE=0 (fresh install):**
   ```bash
   mkdir -p scripts/ralph/runs
   cp -R "$TEMPLATE_DIR/." scripts/ralph/
   cp "$OPENCODE_DIR/bin/flowctl" "$OPENCODE_DIR/bin/flowctl.py" scripts/ralph/
   chmod +x scripts/ralph/ralph.sh scripts/ralph/ralph_once.sh scripts/ralph/flowctl
   ```
   Note: `cp -R templates/.` copies all files including dotfiles (.gitignore).

6. Edit `scripts/ralph/config.env` to set the chosen review backend (skip if UPDATE_MODE=1):
   - Replace `{{PLAN_REVIEW}}` with `<chosen>`
   - Replace `{{WORK_REVIEW}}` with `<chosen>`

7. Print next steps (run from terminal, NOT inside OpenCode):

   **If UPDATE_MODE=1:**
   ```
   Ralph updated! Your config.env was preserved.

   Run from terminal:
   - ./scripts/ralph/ralph_once.sh (one iteration, observe)
   - ./scripts/ralph/ralph.sh (full loop, AFK)
   ```

   **If UPDATE_MODE=0:**
   ```
   Ralph initialized!

   Next steps (run from terminal, NOT inside OpenCode):
   - Edit scripts/ralph/config.env to customize settings
   - ./scripts/ralph/ralph_once.sh (one iteration, observe)
   - ./scripts/ralph/ralph.sh (full loop, AFK)
   - Uninstall: rm -rf scripts/ralph/
   ```
