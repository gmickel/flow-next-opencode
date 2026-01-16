# Plan: Canonical .opencode Source of Truth

## Goal
- Make `.opencode/` the **only** canonical source.
- Eliminate split-state between `.opencode/`, `plugins/flow-next/`, `sync/templates/`.
- Keep install + Ralph + flowctl fully working.

## Current Canonical (today)
- **Canonical for OpenCode behavior:** `.opencode/` in repo root.
- **Runtime dependencies still pulled from:** `plugins/flow-next/` (flowctl + ralph-init templates + docs/scripts).
- **Split-state risk:** `plugins/flow-next/skills/flow-next-ralph-init/templates/*` still diverges from `.opencode/...` unless manually synced.

## Proposed Canonical Layout
- `.opencode/` contains **everything runtime** needs:
  - `.opencode/bin/flowctl` + `.opencode/bin/flowctl.py` (new)
  - `.opencode/skill/flow-next-ralph-init/templates/*` (already present)
  - `.opencode/skill/**` (existing)
  - Docs move to repo-level `docs/` (flowctl + ralph docs)
- `plugins/flow-next/` will be **removed** from installer output and repo after switch. Upstream porting will be manual (no dev copy).

## Switch Strategy (no resets, no split-state)
### Phase 0 — Freeze Canonical
- Declare `.opencode/` authoritative in `AGENTS.md` + `sync/PORTING.md`.
- Rule: **Never edit `plugins/flow-next/**` directly**; only copy from `.opencode/` when needed.

### Phase 1 — Move Runtime Dependencies into .opencode
1) Add `.opencode/bin/flowctl` and `.opencode/bin/flowctl.py`.
2) Update all OpenCode skills to use new path:
   - From: `$PLUGIN_ROOT/plugins/flow-next/scripts/flowctl`
   - To: `.opencode/bin/flowctl` (or `$REPO/.opencode/bin/flowctl`)
3) Update Ralph templates to use `.opencode/bin/flowctl` (prompt_plan/work + ralph.sh logic).

### Phase 2 — Update Install Path
1) `install.sh`: copy only `.opencode/` (and no `plugins/flow-next/`).
2) Ensure `.opencode/bin/flowctl` is executable in installed projects.
3) Move `plugins/flow-next/docs/*` → `docs/` and update all references.

### Phase 3 — Remove Split-State Sources
1) Stop writing to `plugins/flow-next/skills/.../templates`.
2) Delete or archive `plugins/flow-next/` from installer output.
3) Remove `plugins/flow-next/` from repo after switch (manual upstream porting only).

### Phase 4 — Cleanup + Guardrails
1) Add audit step to `sync/PORTING.md`:
   - `rg -n "plugins/flow-next" .opencode/ sync/ plugins/`
   - Must be zero in `.opencode/` + skills.
2) Add CI/script sanity check: fail if `.opencode` references `plugins/flow-next`.

## Required File Changes (checklist)
- [ ] `.opencode/bin/flowctl` + `.opencode/bin/flowctl.py` added
- [ ] `.opencode/skill/*` references updated (flowctl path)
- [ ] `.opencode/skill/flow-next-ralph-init/templates/*` updated
- [ ] `install.sh` updated (copy `.opencode` only)
- [ ] `README.md` + `docs/` updated for new pathing
- [ ] `sync/PORTING.md` updated with new canonical rule
- [ ] `AGENTS.md` updated with new canonical rule

## Tests
- Install into clean repo via `install.sh`.
- `/flow-next:plan` (review opencode + rp) works.
- `/flow-next:work` with `--review=opencode` works.
- `scripts/ralph/ralph.sh --watch` works, shows OpenCode.
- `flowctl` commands run from `.opencode/bin/flowctl` only.

## Risk Elimination Checklist
- [ ] Replace ALL refs to `plugins/flow-next` in `.opencode/` and docs (rg audit must be zero).
- [ ] Run a **fresh install** into a clean repo and verify only `.opencode/` is installed.
- [ ] Run `/flow-next:plan`, `/flow-next:work`, and `scripts/ralph/ralph.sh --watch` from that repo.
- [ ] Verify flowctl path usage is `.opencode/bin/flowctl` everywhere (rg audit).
- [ ] Delete `plugins/flow-next/` only after all tests pass.

## Rollback
- If breakage, temporarily restore prior installer output (copy `.opencode/` only; no plugin dir).
