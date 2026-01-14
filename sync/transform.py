#!/usr/bin/env python3
from pathlib import Path
import shutil

ROOT = Path(__file__).resolve().parents[1]
TPL = ROOT / "sync" / "templates" / "opencode"
DST = ROOT / ".opencode"

if not TPL.exists():
    raise SystemExit(f"missing templates: {TPL}")

for src in TPL.rglob("*"):
    if src.is_dir():
        continue
    rel = src.relative_to(TPL)
    target = DST / rel
    target.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(src, target)
