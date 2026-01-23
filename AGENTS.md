# Notes

- OpenCode logs: `~/.local/share/opencode/log/` (tail for live run status)
- Porting guidance: `sync/PORTING.md` (manual, .opencode is canonical)
- Ralph template source of truth: `.opencode/skill/flow-next-opencode-ralph-init/templates/ralph.sh`
- Smoke test setup (Ralph):
  - `TMP=$(mktemp -d /tmp/flow-next-opencode-smoke.XXXXXX)`
  - `git clone /Users/gordon/work/flow-next-opencode "$TMP" && cd "$TMP"`
  - `git checkout -B main`
  - `./install.sh --project "$PWD"` # refresh .opencode
  - `mkdir -p scripts/ralph/runs`
  - `cp -R .opencode/skill/flow-next-opencode-ralph-init/templates/. scripts/ralph/`
  - `cp .opencode/bin/flowctl .opencode/bin/flowctl.py scripts/ralph/`
  - `chmod +x scripts/ralph/ralph.sh scripts/ralph/ralph_once.sh scripts/ralph/flowctl`
  - `sed -i '' -e 's/{{PLAN_REVIEW}}/opencode/' -e 's/{{WORK_REVIEW}}/opencode/' scripts/ralph/config.env`
  - Acceptance file content: checklist only (no `## Acceptance` heading; flowctl adds it)
