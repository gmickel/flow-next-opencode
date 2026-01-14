#!/usr/bin/env python3
"""
Watch filter for Ralph - parses OpenCode JSON output and shows key events.

Reads JSON lines from stdin, outputs formatted tool calls in TUI style.

CRITICAL: This filter is "fail open" - if output breaks, it continues draining
stdin to prevent SIGPIPE cascading to upstream processes (tee, opencode).

Usage:
    watch-filter.py           # Show tool calls only
    watch-filter.py --verbose # Show tool calls + text responses
"""

import argparse
import json
import os
import sys
from typing import Optional

_output_disabled = False

if sys.stdout.isatty() and not os.environ.get("NO_COLOR"):
    C_RESET = "\033[0m"
    C_DIM = "\033[2m"
    C_CYAN = "\033[36m"
else:
    C_RESET = C_DIM = C_CYAN = ""

INDENT = "   "

ICONS = {
    "bash": "🔧",
    "edit": "📝",
    "write": "📄",
    "read": "📖",
    "grep": "🔍",
    "glob": "📁",
    "task": "🤖",
    "webfetch": "🌐",
    "websearch": "🔎",
    "todoread": "📋",
    "todowrite": "📋",
    "skill": "⚡",
}


def safe_print(msg: str) -> None:
    global _output_disabled
    if _output_disabled:
        return
    try:
        print(msg, flush=True)
    except BrokenPipeError:
        _output_disabled = True


def drain_stdin() -> None:
    try:
        for _ in sys.stdin:
            pass
    except Exception:
        pass


def truncate(s: str, max_len: int = 60) -> str:
    s = s.replace("\n", " ").strip()
    if len(s) > max_len:
        return s[: max_len - 3] + "..."
    return s


def format_tool_use(tool_name: str, tool_input: dict, state: dict) -> str:
    tool = (tool_name or "").lower()
    icon = ICONS.get(tool, "🔹")

    def pick_path(input_obj: dict) -> str:
        if not input_obj:
            return ""
        for key in ("filePath", "file_path", "path", "target", "file"):
            val = input_obj.get(key)
            if isinstance(val, str) and val:
                return val
        return ""

    if tool == "bash":
        cmd = tool_input.get("command", "")
        desc = tool_input.get("description", "")
        if desc:
            return f"{icon} Bash: {truncate(desc)}"
        return f"{icon} Bash: {truncate(cmd, 60)}"

    if tool in ("edit", "write", "read"):
        path = pick_path(tool_input)
        if not path:
            path = state.get("title", "") if isinstance(state, dict) else ""
        return f"{icon} {tool.capitalize()}: {path.split('/')[-1] if path else 'unknown'}"

    if tool == "grep":
        pattern = tool_input.get("pattern", "")
        return f"{icon} Grep: {truncate(pattern, 40)}"

    if tool == "glob":
        pattern = tool_input.get("pattern", "")
        return f"{icon} Glob: {pattern}"

    if tool == "task":
        desc = tool_input.get("description", "")
        agent = tool_input.get("subagent_type", "")
        return f"{icon} Task ({agent}): {truncate(desc, 50)}"

    if tool == "skill":
        skill = tool_input.get("name", "") or tool_input.get("skill", "")
        return f"{icon} Skill: {skill}"

    if tool in ("todoread", "todowrite"):
        todos = tool_input.get("todos", []) or []
        in_progress = [t for t in todos if t.get("status") == "in_progress"]
        if in_progress:
            return f"{icon} Todo: {truncate(in_progress[0].get('content', ''))}"
        return f"{icon} Todo: {len(todos)} items"

    return f"{icon} {tool_name}"


def process_event(event: dict, verbose: bool) -> None:
    etype = event.get("type", "")

    if etype == "tool_use":
        part = event.get("part", {})
        tool_name = part.get("tool", "")
        state = part.get("state", {}) or {}
        tool_input = state.get("input", {}) or {}
        formatted = format_tool_use(tool_name, tool_input, state)
        safe_print(f"{INDENT}{C_DIM}{formatted}{C_RESET}")
        return

    if etype == "text" and verbose:
        part = event.get("part", {})
        text = part.get("text", "")
        if text.strip():
            safe_print(f"{INDENT}{C_CYAN}💬 {text}{C_RESET}")
        return

    if etype == "error":
        err = event.get("error", {})
        msg = err.get("message") or err.get("name") or str(err)
        if msg:
            safe_print(f"{INDENT}{C_DIM}❌ {truncate(msg, 80)}{C_RESET}")


def main() -> None:
    parser = argparse.ArgumentParser(description="Filter OpenCode JSON output")
    parser.add_argument(
        "--verbose",
        action="store_true",
        help="Show text in addition to tool calls",
    )
    args = parser.parse_args()

    for line in sys.stdin:
        line = line.strip()
        if not line:
            continue
        try:
            event = json.loads(line)
        except json.JSONDecodeError:
            continue
        try:
            process_event(event, args.verbose)
        except Exception:
            # Fail open: stop output but drain stdin
            global _output_disabled
            _output_disabled = True
            drain_stdin()
            return


if __name__ == "__main__":
    main()
