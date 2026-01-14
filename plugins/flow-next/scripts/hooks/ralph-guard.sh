#!/usr/bin/env bash
set -euo pipefail

# Only active in Ralph mode
if [[ -z "${FLOW_RALPH:-}" && -z "${REVIEW_RECEIPT_PATH:-}" ]]; then
  exit 0
fi

python3 - <<'PY'
import json
import sys
import os
import hashlib

try:
    data = json.load(sys.stdin)
except Exception:
    sys.exit(0)

if data.get("tool_name") != "Bash":
    sys.exit(0)

cmd = (data.get("tool_input") or {}).get("command") or ""

# Block direct rp-cli usage
if "rp-cli" in cmd:
    print("Ralph mode: use flowctl rp wrappers only (no rp-cli).", file=sys.stderr)
    sys.exit(2)

# Block prep-chat (deprecated)
if "flowctl prep-chat" in cmd:
    print("Ralph mode: use flowctl rp chat-send (no prep-chat).", file=sys.stderr)
    sys.exit(2)

try:
    import shlex
    tokens = shlex.split(cmd)
except Exception:
    tokens = cmd.split()

def token_has_flowctl(tok: str) -> bool:
    return "flowctl" in tok

def flag_value(flag: str):
    for i, tok in enumerate(tokens):
        if tok.startswith(flag + "="):
            return tok.split("=", 1)[1]
        if tok == flag and i + 1 < len(tokens):
            return tokens[i + 1]
    return None

# Check for direct builder call (should use setup-review instead)
if "rp" in tokens and "builder" in tokens and any(token_has_flowctl(t) for t in tokens):
    # In Ralph mode, builder should only be called via setup-review
    # If called directly, block it
    print("Ralph mode: use 'flowctl rp setup-review' instead of 'flowctl rp builder'.", file=sys.stderr)
    print("setup-review handles pick-window + workspace + builder atomically.", file=sys.stderr)
    sys.exit(2)

# Validate pick-window and ensure-workspace also redirect to setup-review
if "rp" in tokens and ("pick-window" in tokens or "ensure-workspace" in tokens) and any(token_has_flowctl(t) for t in tokens):
    print("Ralph mode: use 'flowctl rp setup-review' for atomic window + workspace + builder setup.", file=sys.stderr)
    sys.exit(2)

# Validate chat-send has required args
if "rp" in tokens and "chat-send" in tokens and any(token_has_flowctl(t) for t in tokens):
    window = flag_value("--window")
    tab = flag_value("--tab")
    message_file = flag_value("--message-file")

    if not window:
        print("Ralph mode: flowctl rp chat-send requires --window.", file=sys.stderr)
        sys.exit(2)
    if not window.isdigit():
        print("Ralph mode: flowctl rp chat-send --window must be numeric.", file=sys.stderr)
        sys.exit(2)
    if not tab:
        print("Ralph mode: flowctl rp chat-send requires --tab.", file=sys.stderr)
        sys.exit(2)
    if not message_file:
        print("Ralph mode: flowctl rp chat-send requires --message-file.", file=sys.stderr)
        sys.exit(2)

# Validate select-add/select-get have required args
if "rp" in tokens and ("select-add" in tokens or "select-get" in tokens) and any(token_has_flowctl(t) for t in tokens):
    window = flag_value("--window")
    tab = flag_value("--tab")

    if not window:
        print("Ralph mode: flowctl rp select-* requires --window.", file=sys.stderr)
        sys.exit(2)
    if not window.isdigit():
        print("Ralph mode: flowctl rp select-* --window must be numeric.", file=sys.stderr)
        sys.exit(2)
    if not tab:
        print("Ralph mode: flowctl rp select-* requires --tab.", file=sys.stderr)
        sys.exit(2)

# Validate prompt-get/prompt-set have required args
if "rp" in tokens and ("prompt-get" in tokens or "prompt-set" in tokens) and any(token_has_flowctl(t) for t in tokens):
    window = flag_value("--window")
    tab = flag_value("--tab")

    if not window:
        print("Ralph mode: flowctl rp prompt-* requires --window.", file=sys.stderr)
        sys.exit(2)
    if not window.isdigit():
        print("Ralph mode: flowctl rp prompt-* --window must be numeric.", file=sys.stderr)
        sys.exit(2)
    if not tab:
        print("Ralph mode: flowctl rp prompt-* requires --tab.", file=sys.stderr)
        sys.exit(2)

sys.exit(0)
PY
