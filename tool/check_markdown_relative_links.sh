#!/usr/bin/env bash
# Fail when tracked Markdown relative links point at missing paths.
# Skips http(s)/mailto/data and fragment-only targets. Historical change notes
# are included — broken hrefs confuse agents who follow them.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

python3 - <<'PY'
from __future__ import annotations

import os
import re
import sys
from pathlib import Path

root = Path(".").resolve()
skip_dir_parts = {
    ".git",
    ".agents",
    "vendor",
    "DerivedData",
    "node_modules",
    ".dart_tool",
    "build",
    ".ios",
    ".android",
}
# Match lint-markdown ignore intent for generated Fastlane README noise.
skip_glob_prefixes = (
    "fastlane/",
    "flutter_module/.ios/",
    "flutter_module/.android/",
    "flutter_module/.dart_tool/",
    "flutter_module/build/",
)

link_re = re.compile(r"(?<!!)\[[^\]]*\]\(([^)]+)\)")
broken: list[tuple[str, str]] = []

def should_skip(rel: str) -> bool:
    if any(rel.startswith(p) for p in skip_glob_prefixes):
        return True
    parts = Path(rel).parts
    return any(p in skip_dir_parts for p in parts)

for dirpath, dirnames, filenames in os.walk(root):
    # prune in-place
    dirnames[:] = [d for d in dirnames if d not in skip_dir_parts]
    for name in filenames:
        if not name.endswith(".md"):
            continue
        path = Path(dirpath) / name
        rel = path.relative_to(root).as_posix()
        if should_skip(rel):
            continue
        try:
            text = path.read_text(encoding="utf-8")
        except OSError as exc:
            print(f"error: cannot read {rel}: {exc}", file=sys.stderr)
            sys.exit(1)
        for match in link_re.finditer(text):
            raw = match.group(1).strip()
            # Drop optional title: (url "title")
            url = raw.split()[0] if raw else ""
            url = url.strip("<>")
            if not url or url.startswith("#"):
                continue
            if re.match(r"^(https?|mailto|data|tel):", url, re.I):
                continue
            # Drop fragment for existence check
            path_part = url.split("#", 1)[0]
            if not path_part:
                continue
            target = (path.parent / path_part).resolve()
            try:
                target.relative_to(root)
            except ValueError:
                # Allow links that resolve outside repo only if they exist
                # (rare); still require existence.
                pass
            if not target.exists():
                broken.append((rel, url))

if broken:
    print("error: broken Markdown relative links:", file=sys.stderr)
    for src, url in broken:
        print(f"  {src} -> {url}", file=sys.stderr)
    sys.exit(1)

print("Markdown relative links OK.")
PY
