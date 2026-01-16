# Porting Playbook (Manual, .opencode‑first)

Goal: keep this OpenCode port aligned with upstream with **manual, minimal edits**.

## Canonical Source

**Only `.opencode/` is canonical.**
- Do not edit `plugins/flow-next/**` (removed after switch).
- Do not use `sync/templates` or `sync/transform.py` (deleted).

## Porting Steps (manual)

1) Review upstream changes in `gmickel-claude-marketplace` (plugins/flow-next).
2) Apply required changes **directly** to our `.opencode/` equivalents.
3) If flowctl changes upstream, update:
   - `.opencode/bin/flowctl`
   - `.opencode/bin/flowctl.py`
4) If ralph templates change upstream, update:
   - `.opencode/skill/flow-next-ralph-init/templates/*`
5) If docs change upstream, update:
   - `docs/*`

## OpenCode Invariants (do not regress)

- Backend name: `opencode` only (no codex).
- Question tool only in `/flow-next:setup`.
- Reviewer uses task tool subagent `opencode-reviewer` and reuses `session_id`.
- flowctl path: `.opencode/bin/flowctl`.
- Ralph runner agent: `ralph-runner` configured in `.opencode/opencode.json`.

## Pre-commit Audit

- `rg -n "plugins/flow-next" .opencode docs README.md` => **no matches**
- `rg -n "sync/templates|transform.py|sync/run.sh" .` => **no matches**
- `rg -n "opencode/bin/flowctl" .opencode` => **matches expected**

## Tests (when touched)

- flowctl changes: run a fresh repo and validate with `flowctl validate --all`.
- ralph changes: run a fresh repo with `/flow-next:ralph-init` and `scripts/ralph/ralph.sh --watch`.
