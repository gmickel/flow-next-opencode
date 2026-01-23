#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: scripts/ralph-smoke.sh [--dir PATH] [--no-task]

Creates a clean Ralph fixture repo for smoke testing.
Defaults to /tmp/flow-next-opencode-smoke (must not already exist).

Options:
  --dir PATH   Target directory (must not exist)
  --no-task    Skip creating the smoke epic/task
EOF
}

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUTDIR="/tmp/flow-next-opencode-smoke"
CREATE_TASK=1

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dir)
      OUTDIR="${2:-}"
      shift 2
      ;;
    --no-task)
      CREATE_TASK=0
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown arg: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

command -v git >/dev/null 2>&1 || { echo "git required" >&2; exit 1; }
command -v jq >/dev/null 2>&1 || { echo "jq required" >&2; exit 1; }
PYTHON_BIN="${PYTHON_BIN:-}"
if [[ -n "$PYTHON_BIN" ]]; then
  command -v "$PYTHON_BIN" >/dev/null 2>&1 || PYTHON_BIN=""
fi
if [[ -z "$PYTHON_BIN" ]]; then
  if command -v python3 >/dev/null 2>&1; then PYTHON_BIN="python3"; fi
fi
if [[ -z "$PYTHON_BIN" ]]; then
  if command -v python >/dev/null 2>&1; then PYTHON_BIN="python"; fi
fi
if [[ -z "$PYTHON_BIN" ]]; then
  echo "python3 or python required" >&2
  exit 1
fi

if [[ -z "$OUTDIR" ]]; then
  echo "--dir requires a path" >&2
  exit 1
fi
if [[ -e "$OUTDIR" ]]; then
  echo "Target exists: $OUTDIR" >&2
  echo "Choose a new path or remove it manually." >&2
  exit 1
fi

git clone "$ROOT" "$OUTDIR" >/dev/null
git -C "$OUTDIR" checkout -B main >/dev/null

(
  cd "$OUTDIR"
  ./install.sh --project "$PWD" >/dev/null
  mkdir -p scripts/ralph/runs
  cp -R .opencode/skill/flow-next-opencode-ralph-init/templates/. scripts/ralph/
  cp .opencode/bin/flowctl .opencode/bin/flowctl.py scripts/ralph/
  chmod +x scripts/ralph/ralph.sh scripts/ralph/ralph_once.sh scripts/ralph/flowctl
  sed -i '' -e 's/{{PLAN_REVIEW}}/opencode/' -e 's/{{WORK_REVIEW}}/opencode/' scripts/ralph/config.env
  git add scripts/ralph
  git commit -m "chore: add ralph fixture" >/dev/null

  if [[ "$CREATE_TASK" == "1" ]]; then
    ./scripts/ralph/flowctl init >/dev/null
    ACCEPT="$(mktemp /tmp/flow-next-opencode-acceptance.XXXXXX)"
    cat > "$ACCEPT" <<'EOF'
- [ ] Create `docs/smoke-task.md` with a single line: `smoke ok`
- [ ] Run `git status --porcelain=v1`
- [ ] Run `git show --stat`
EOF
    EPIC_ID="$(./scripts/ralph/flowctl epic create --title "Smoke Epic" --json | jq -r '.id')"
    TASK_ID="$(./scripts/ralph/flowctl task create --epic "$EPIC_ID" --title "Smoke Task" --acceptance-file "$ACCEPT" --json | jq -r '.id')"
    TASK_PATH=".flow/tasks/$TASK_ID.md"
    "$PYTHON_BIN" - "$TASK_PATH" <<'PY'
import sys
path = sys.argv[1]
data = open(path, "r", encoding="utf-8").read()
lines = data.splitlines()
desc = "Create docs/smoke-task.md with a single line 'smoke ok' for opencode review."
for i, line in enumerate(lines):
    if line.strip() == "## Description":
        # Normalize to: header, blank line, description
        insert_at = i + 1
        if insert_at < len(lines) and lines[insert_at].strip() == "":
            insert_at += 1
        if insert_at < len(lines) and lines[insert_at].strip().upper() == "TBD":
            lines[insert_at] = desc
        else:
            lines.insert(i + 1, "")
            lines.insert(i + 2, desc)
        break
out = "\n".join(lines)
if data.endswith("\n"):
    out += "\n"
open(path, "w", encoding="utf-8").write(out)
PY
    echo "EPIC_ID=$EPIC_ID"
    echo "TASK_ID=$TASK_ID"
  fi
)

echo "READY=$OUTDIR"
