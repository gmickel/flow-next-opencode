#!/usr/bin/env bash
set -euo pipefail

if [[ -z "${FLOW_RALPH_VERBOSE:-}" ]]; then
  exit 0
fi

if [[ -z "${REVIEW_RECEIPT_PATH:-}" ]]; then
  exit 0
fi

payload="$(cat)"
if [[ -z "$payload" ]]; then
  exit 0
fi

run_dir="$(dirname "$(dirname "$REVIEW_RECEIPT_PATH")")"
log_file="$run_dir/ralph.log"
ids_file="$run_dir/ralph.log.ids"

tool_id="$(python3 - <<'PY' <<<"$payload"
import json, sys
try:
    data = json.load(sys.stdin)
except Exception:
    print("")
    sys.exit(0)
print(data.get("tool_use_id") or "")
PY
)"

if [[ -n "$tool_id" ]]; then
  if [[ -f "$ids_file" ]]; then
    if command -v rg >/dev/null 2>&1; then
      if rg -q --fixed-strings "$tool_id" "$ids_file"; then
        exit 0
      fi
    elif grep -qF "$tool_id" "$ids_file"; then
      exit 0
    fi
  fi
  echo "$tool_id" >> "$ids_file"
fi

ts="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
{
  echo "ts=$ts"
  echo "cwd=$PWD"
  echo "$payload"
  echo "---"
} >> "$log_file"
