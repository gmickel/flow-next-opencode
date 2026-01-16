# Porting Playbook (Minimal, OpenCode-first)

Goal: keep this OpenCode port aligned with upstream with **minimal, surgical edits**.

## Non‑negotiables (OpenCode‑specific)

Do NOT change these unless absolutely required:

- OpenCode config discovery + plugin order
- OpenCode question tool usage vs text rules
- OpenCode agent config (no `model:` in agent frontmatter)
- OpenCode backend naming (`opencode`)
- Ralph strings/UX that say “OpenCode”
- Batch tool usage in plan skills (OpenCode batch)

If upstream changes conflict, only adjust the smallest surface needed to keep OpenCode working.

## Minimal Sync Steps

1) Pull upstream to `/tmp/gmickel-claude-marketplace-main` (or `~/work/...`).
2) `git diff --name-only <last_port_sha>..origin/main -- plugins/flow-next`
3) Copy **only changed files**.
4) Apply **minimal** OpenCode deltas (only if needed).
5) Update `.opencode/` + `sync/templates/` **only when the change affects those files**.
6) Run targeted tests (`ci_test.sh`, `smoke_test.sh`) only if flowctl/ralph changed.
7) Commit per upstream change.

## Diff Triage (keep edits atomic)

Before touching files:

- Enumerate changes by file type:
  - **flowctl** (`scripts/flowctl.py`, `flowctl`): behavior changes → must port.
  - **Ralph** (`scripts/ralph*.sh`, `skills/flow-next-ralph-init/templates/*`): behavior + UI → must port.
  - **Skills** (`skills/**/SKILL.md`, `workflow.md`, `steps.md`): instructions → must port with OpenCode rules applied.
  - **Docs** (`docs/*.md`, `README.md`): keep in sync unless OpenCode‑specific divergence.
- Decide per file: **mirror** (no edits) vs **port** (apply OpenCode deltas).
- Only port files that *actually changed upstream*.

## Minimal Edit Rules

- **Do not rewrite** files. Apply tiny, local edits.
- **Preserve upstream order + wording** unless it conflicts with OpenCode invariants.
- **One change = one commit** (keep diffs reviewable).
- **Never change both mirror + template** unless the mirror change actually needs OpenCode edits.

## Port Flow (deterministic)

1) Copy updated upstream file(s) into `plugins/flow-next/`.
2) If OpenCode deltas needed, patch **only** the affected file(s):
   - `sync/templates/opencode/**` for OpenCode templates
   - `.opencode/**` only via `sync/transform.py` (never edit directly)
3) Run:
   - `python3 sync/transform.py` (only if templates changed)
   - `sync/verify.sh` (always)
4) Tests:
   - flowctl changes → run `plugins/flow-next/scripts/smoke_test.sh` from `/tmp`
   - ralph changes → run `plugins/flow-next/scripts/ralph_smoke_test.sh` from `/tmp`

## When to Use `sync/run.sh`

Use `sync/run.sh` **only** when upstream has many changes across skills/agents/commands and you want a full mirror refresh.
Otherwise, prefer manual file copy + minimal patches (smaller diffs, easier review).

## Audit Checklist (pre-commit)

- `sync/verify.sh` passes
- `.opencode/` has no `AskUserQuestion` strings
- Backend names in skills/docs: `opencode` only
- Models set in `.opencode/opencode.json` (not in agent frontmatter)
- Question tool only in `/flow-next:setup`; other workflows ask plain text
- Ralph templates mention OpenCode (not Claude/Codex)

## OpenCode Config Facts (from `repos/opencode`)

Keep these in mind when porting; they explain why our layout is the way it is:

- Config precedence: remote < global config (`~/.config/opencode/opencode.json[c]`) < `OPENCODE_CONFIG` < project `opencode.json[c]` < `OPENCODE_CONFIG_CONTENT`.
- `.opencode/` directories are discovered upward; if present, `.opencode/opencode.json[c]` is loaded too.
- Commands/agents/plugins are loaded from `.opencode/command`, `.opencode/agent`, `.opencode/plugin` (and non-dot `/command`, `/agent`).
- Plugins are deduped by name; priority order (highest wins): local `plugin/` dir > local `opencode.json` > global `plugin/` dir > global `opencode.json`.
- Question tool schema: `header` max 12 chars, `options` have `label` + `description`, optional `multiple`, optional `custom` (defaults true). Answers are arrays of selected labels.
- Config has `experimental.batch_tool` flag; keep enabled for our skills.

## OpenCode Port Invariants (do not regress)

- `opencode.json` lives in `.opencode/` for installs; keep templates aligned.
- Agent frontmatter (`.opencode/agent/*.md`) must NOT include model; models live in `.opencode/opencode.json` `agent` block.
- Question tool usage:
  - `/flow-next:setup` uses question tool.
  - Plan/work/plan-review/impl-review use plain text questions (voice-friendly).
- Backend name is `opencode` only. No `codex` backend.
- Reviewer agent = `opencode-reviewer` with `reasoningEffort` in `.opencode/opencode.json`.
- Ralph runner agent = `ralph-runner` with model set in `.opencode/opencode.json`.
- Subagents keep tools locked down (`write/edit/patch/multiedit: false`).
- Re-review loops must reuse `session_id` for subagent continuity (OpenCode task tool).
- OpenCode review uses **task tool + subagent** (`opencode-reviewer`). Do not use `opencode run` for reviews.

## Where to Patch (if required)

- `plugins/flow-next/**` = primary source in this repo
- `.opencode/**` = runtime OpenCode install
- `sync/templates/**` = install/sync overrides

## Example Scope (stdin + set‑spec)

- Copy `flowctl.py`, `smoke_test.sh`, and the specific skills touched upstream.
- Adjust only where OpenCode diverges (question tool, backend naming, batch tool).
- Do **not** rewrite entire skills.
