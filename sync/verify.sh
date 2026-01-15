#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"

if [[ -d "$ROOT/plugins/flow-next/commands" ]]; then
  echo "plugins/flow-next/commands should not exist" >&2
  exit 1
fi

if grep -R -n "AskUserQuestion" "$ROOT/.opencode" | grep -v "flow-next-ralph-init/templates/watch-filter.py" >/dev/null; then
  echo "AskUserQuestion found in .opencode (must use OpenCode question tool)" >&2
  grep -R -n "AskUserQuestion" "$ROOT/.opencode" | grep -v "flow-next-ralph-init/templates/watch-filter.py" >&2
  exit 1
fi

if grep -R -n -i "codex" "$ROOT/.opencode" | grep -v "opencode.json" >/dev/null; then
  echo "codex references found in .opencode (not supported)" >&2
  grep -R -n -i "codex" "$ROOT/.opencode" | grep -v "opencode.json" >&2
  exit 1
fi

if grep -R -n "CLAUDE_" "$ROOT/.opencode" | grep -v "flow-next-ralph-init/templates" >/dev/null; then
  echo "CLAUDE_ references found outside ralph templates" >&2
  grep -R -n "CLAUDE_" "$ROOT/.opencode" | grep -v "flow-next-ralph-init/templates" >&2
  exit 1
fi
