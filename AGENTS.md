# Notes

- OpenCode logs: `~/.local/share/opencode/log/` (tail for live run status)
- Porting guidance: `sync/PORTING.md` (manual, .opencode is canonical)
- Ralph template source of truth: `.opencode/skill/flow-next-opencode-ralph-init/templates/ralph.sh`
- Ralph smoke test (deterministic fixture):
  - `scripts/ralph-smoke.sh --dir /tmp/flow-next-opencode-smoke.X`
  - `cd /tmp/flow-next-opencode-smoke.X`
  - `./scripts/ralph/ralph_once.sh --watch`
