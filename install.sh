#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
PROJECT="${PROJECT:-$(pwd)}"

usage() {
  echo "Usage: $0 --project <path>"
  echo "  or: PROJECT=<path> $0"
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

while [[ $# -gt 0 ]]; do
  case "$1" in
    --project)
      PROJECT="$2"
      shift 2
      ;;
    *)
      echo "Unknown arg: $1"
      usage
      exit 1
      ;;
  esac
done

if [[ -z "${PROJECT:-}" ]]; then
  usage
  exit 1
fi

install_project() {
  mkdir -p "$PROJECT/.opencode" "$PROJECT/plugins"

  rsync -a "$ROOT/.opencode/command" "$ROOT/.opencode/skill" "$ROOT/.opencode/agent" "$ROOT/.opencode/plugin" "$PROJECT/.opencode/"

  if [[ ! -f "$PROJECT/.opencode/opencode.json" && -f "$ROOT/.opencode/opencode.json" ]]; then
    rsync -a "$ROOT/.opencode/opencode.json" "$PROJECT/.opencode/"
  fi

  rsync -a "$ROOT/plugins/flow-next" "$PROJECT/plugins/"
}

install_project

printf "done\nproject: %s\n" "$PROJECT"
