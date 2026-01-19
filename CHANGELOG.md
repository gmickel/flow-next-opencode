# Changelog

## Unreleased

**Restores parity with upstream Claude Code plugin (flow-next 0.12.10 + 0.13.0).**

### Planning Workflow Changes (ported from upstream 0.13.0)

**The Problem:** Plans were doing implementation work — complete function bodies, full interface definitions, copy-paste ready code blocks. This wasted tokens in planning, review, AND implementation.

**The Solution:** Plans describe WHAT to build and WHERE to look — not HOW to implement.

#### Added

- **"The Golden Rule" in SKILL.md** — Explicit guidance on what code belongs in plans
  - ✅ Allowed: Signatures, file:line refs, recent/surprising APIs, non-obvious gotchas
  - ❌ Forbidden: Complete implementations, full class bodies, copy-paste snippets (>10 lines)

- **Task sizing with T-shirt sizes** — Observable metrics instead of token estimates
  | Size | Files | Acceptance | Pattern | Action |
  |------|-------|------------|---------|--------|
  | S | 1-2 | 1-3 | Follows existing | ✅ Good |
  | M | 3-5 | 3-5 | Adapts existing | ✅ Good |
  | L | 5+ | 5+ | New/novel | ⚠️ Split |

- **Plan depth selection** — `--depth=short|standard|deep` or answer in setup questions

- **Stakeholder analysis step** — New Step 2 asks who's affected (users, devs, ops)

- **Mermaid diagram guidance** — For data model and architecture changes

- **Expanded examples.md** — Complete rewrite with good/bad examples

- **"Current year is 2026" note** — Added to docs-scout, practice-scout, github-scout

- **github-scout agent** — Cross-repo code search via `gh` CLI with quality tiers

#### Changed

- **Subagent output rules** — All research scouts limit snippets to <10 lines, focus on "where to look"
- **Default depth is STANDARD** — Balanced detail; short/deep on request

### Implementation Review Improvements (ported from upstream 0.13.0 + 0.12.10)

- **Scenario exploration checklist** — Reviewers walk through 9 failure scenarios for changed code
- **Verdict scope tightened** — Reviews focus on issues in the changeset, not pre-existing codebase issues
- Added to `build_review_prompt()` and `build_standalone_review_prompt()` in flowctl.py
- Added to workflow.md for RP backend

### Ralph Improvements (ported from upstream 0.12.10)

- **WORKER_TIMEOUT default increased** — 30min → 45min (2700s)
- **Iteration tracking in receipts** — `"iteration": N` for debugging
- **Enhanced timeout logging** — Logs phase, task/epic ID, iteration, suggests fix
- **ralph-init UPDATE_MODE** — Can now update existing Ralph setup while preserving `config.env`

### Bugfixes

- **Fixed missing verdict in receipts** — Receipt JSON now includes `"verdict":"SHIP"` as required by `verify_receipt`

### Other

- Rename OpenCode skills to `flow-next-opencode-*` to avoid Claude skill collisions
- Thanks @gmickel for the contribution

## 0.2.3

- Canonicalize `.opencode/` (remove legacy plugin/sync paths)
- Docs moved to `docs/` with updated links
- Ralph receipts now require verdicts

## 0.2.1

- Add browser skill (standalone)

## 0.2.2

- flowctl stdin support + Windows-safe codex exec piping
- flowctl status output + artifact-file guards
- Ralph Windows hardening + watch filter updates
- Plan/interview flows: stdin + task set-spec efficiency
- Docs: flowctl commands (checkpoint/status/task reset) restored
- Sync/porting guardrails updated for OpenCode

## 0.2.0

- Ralph (autonomous loop) + opencode runner/reviewer config
- OpenCode review session reuse for re-reviews
- Ralph hooks + watch stream for tool calls
- Updated Ralph docs + OpenCode config notes
- Ralph run control (pause/resume/stop/status) + sentinel support
- flowctl task reset + epic add-dep/rm-dep

## 0.1.0

- initial release (OpenCode port)
