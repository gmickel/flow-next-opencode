#!/usr/bin/env bash
set -euo pipefail

if [[ -z "${FLOW_RALPH:-}" && -z "${REVIEW_RECEIPT_PATH:-}" ]]; then
  exit 0
fi

if [[ -z "${REVIEW_RECEIPT_PATH:-}" ]]; then
  exit 0
fi

if [[ ! -f "$REVIEW_RECEIPT_PATH" ]]; then
  echo "Missing review receipt: $REVIEW_RECEIPT_PATH" >&2
  exit 2
fi

python3 - "$REVIEW_RECEIPT_PATH" <<'PY'
import json
import sys

path = sys.argv[1]
try:
    with open(path, encoding="utf-8") as f:
        data = json.load(f)
except Exception as e:
    print(f"Invalid receipt JSON: {e}", file=sys.stderr)
    sys.exit(2)

if not isinstance(data, dict):
    print("Invalid receipt JSON: expected object", file=sys.stderr)
    sys.exit(2)

if not data.get("type") or not data.get("id"):
    print("Invalid receipt JSON: missing type/id", file=sys.stderr)
    sys.exit(2)

sys.exit(0)
PY
