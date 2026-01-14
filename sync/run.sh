#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SOURCE="${FLOW_NEXT_SRC:-/Users/gordon/work/gmickel-claude-marketplace/plugins/flow-next}"

if [[ ! -d "$SOURCE" ]]; then
  echo "missing SOURCE: $SOURCE" >&2
  exit 1
fi

mkdir -p "$ROOT/plugins"

# 1) mirror upstream into plugins/flow-next
rsync -a --delete "$SOURCE/" "$ROOT/plugins/flow-next/"

# 2) rename upstream commands to keep as mirror only
if [[ -d "$ROOT/plugins/flow-next/commands" ]]; then
  rm -rf "$ROOT/plugins/flow-next/_commands"
  mv "$ROOT/plugins/flow-next/commands" "$ROOT/plugins/flow-next/_commands"
fi

# 3) copy upstream commands/skills/agents into .opencode as baseline
mkdir -p "$ROOT/.opencode/command/flow-next" "$ROOT/.opencode/skill" "$ROOT/.opencode/agent"
rsync -a "$ROOT/plugins/flow-next/_commands/flow-next/" "$ROOT/.opencode/command/flow-next/"
rsync -a "$ROOT/plugins/flow-next/skills/" "$ROOT/.opencode/skill/"
rsync -a "$ROOT/plugins/flow-next/agents/" "$ROOT/.opencode/agent/"

# 4) apply OpenCode overrides
python3 "$ROOT/sync/transform.py"

# 5) verify
"$ROOT/sync/verify.sh"
