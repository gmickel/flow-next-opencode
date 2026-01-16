# Flow-Next Setup Workflow

Follow these steps in order. This workflow is **idempotent** - safe to re-run.

## Step 0: Resolve OpenCode path

Use repo-local OpenCode root:

```bash
ROOT="$(git rev-parse --show-toplevel)"
OPENCODE_DIR="$ROOT/.opencode"
VERSION_FILE="$OPENCODE_DIR/version"
```

## Step 1: Check .flow/ exists

Check if `.flow/` directory exists (use Bash `ls .flow/` or check for `.flow/meta.json`).

- If `.flow/` exists: continue
- If `.flow/` doesn't exist: create it with `mkdir -p .flow` and create minimal meta.json:
  ```json
  {"schema_version": 2, "next_epic": 1}
  ```

Also ensure `.flow/config.json` exists with defaults:
```bash
if [ ! -f .flow/config.json ]; then
  echo '{"memory":{"enabled":false}}' > .flow/config.json
fi
```

## Step 2: Check existing setup

Read `.flow/meta.json` and check for `setup_version` field.

Also read `${VERSION_FILE}` to get current version (fallback `unknown`):
```bash
OPENCODE_VERSION="$(cat "$VERSION_FILE" 2>/dev/null || echo "unknown")"
```

**If `setup_version` exists (already set up):**
- If **same version as `OPENCODE_VERSION`**: ask with the **question** tool:
  - **Header**: `Update Docs`
  - **Question**: `Already set up with v<OPENCODE_VERSION>. Update docs only?`
  - **Options**:
    1. `Yes, update docs`
    2. `No, exit`
  - If yes: skip to Step 6 (docs)
  - If no: done
- If **older version**: tell user "Updating from v<OLD> to v<NEW>" and continue

**If no `setup_version`:** continue (first-time setup)

## Step 3: Create .flow/bin/

```bash
mkdir -p .flow/bin
```

## Step 4: Copy files

**IMPORTANT: Do NOT read flowctl.py - it's too large. Just copy it.**

Copy using Bash `cp` with absolute paths:

```bash
cp "${OPENCODE_DIR}/bin/flowctl" .flow/bin/flowctl
cp "${OPENCODE_DIR}/bin/flowctl.py" .flow/bin/flowctl.py
chmod +x .flow/bin/flowctl
```

Then read [templates/usage.md](templates/usage.md) and write it to `.flow/usage.md`.

## Step 5: Update meta.json

Read current `.flow/meta.json`, add/update these fields (preserve all others):

```json
{
  "setup_version": "<OPENCODE_VERSION>",
  "setup_date": "<ISO_DATE>"
}
```

## Step 6: Check and update documentation

Read the template from [templates/claude-md-snippet.md](templates/claude-md-snippet.md).

For each of CLAUDE.md and AGENTS.md:
1. Check if file exists
2. If exists, check if `<!-- BEGIN FLOW-NEXT -->` marker exists
3. If marker exists, extract content between markers and compare with template

Determine status for each file:
- **missing**: file doesn't exist or no flow-next section
- **current**: section exists and matches template
- **outdated**: section exists but differs from template

Based on status:

**If both are current:**
```
Documentation already up to date (CLAUDE.md, AGENTS.md).
```
Skip to Step 7.

**If one or both need updates:**
Show status in text, then ask with the **question** tool:
- **Header**: `Docs Update`
- **Question**: `Which docs should be updated?`
- **Options**: only include choices for files that are **missing** or **outdated**, plus `Skip`
  - `CLAUDE.md only` (if needed)
  - `AGENTS.md only` (if needed)
  - `Both` (if both needed)
  - `Skip`

Wait for response, then for each chosen file:
1. Read the file (create if doesn't exist)
2. If marker exists: replace everything between `<!-- BEGIN FLOW-NEXT -->` and `<!-- END FLOW-NEXT -->` (inclusive)
3. If no marker: append the snippet

## Step 7: Print summary

```
Flow-Next setup complete!

Installed:
- .flow/bin/flowctl (v<OPENCODE_VERSION>)
- .flow/bin/flowctl.py
- .flow/usage.md

To use from command line:
  export PATH=".flow/bin:$PATH"
  flowctl --help

Documentation updated:
- <files updated or "none">

Memory system: disabled by default
Enable with: flowctl config set memory.enabled true

Notes:
- Re-run /flow-next:setup after .opencode updates to refresh scripts
- Uninstall: rm -rf .flow/bin .flow/usage.md and remove <!-- BEGIN/END FLOW-NEXT --> block from docs
```

## Step 8: Ask about starring

Ask with the **question** tool:
- **Header**: `Support Flow-Next`
- **Question**: `Flow-Next is free and open source. Would you like to ⭐ star the repo on GitHub to support the project?`
- **Options**:
  1. `Yes, star the repo`
  2. `No thanks`

**If yes:**
1. Check if `gh` CLI is available: `which gh`
2. If available, run: `gh api -X PUT /user/starred/gmickel/flow-next-opencode`
3. If `gh` not available or command fails, provide the link:
   ```
   Star manually: https://github.com/gmickel/flow-next-opencode
   ```

**If no:** Thank them and complete setup without starring.
