#!/usr/bin/env bash
# Fail when tracked Markdown relative links point at missing paths.
# Skips http(s)/mailto/data and fragment-only targets. Historical change notes
# are included — broken hrefs confuse agents who follow them.
#
# Usage:
#   ./tool/check_markdown_relative_links.sh
#   ./tool/check_markdown_relative_links.sh --self-test   # fixture only
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

usage() {
  sed -n '2,9p' "$0" | sed 's/^# \{0,1\}//'
}

case "${1:-}" in
  -h|--help|help)
    usage
    exit 0
    ;;
  --self-test)
    echo "==> Markdown relative-link self-test (fixtures)"
    python3 - <<'PY'
from __future__ import annotations

import os
import re
import shutil
import sys
import tempfile
from pathlib import Path

link_re = re.compile(r"(?<!!)\[[^\]]*\]\(([^)]+)\)")
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
    "fixtures",
}


def broken_links(scan_root: Path) -> list[tuple[str, str]]:
    broken: list[tuple[str, str]] = []
    for dirpath, dirnames, filenames in os.walk(scan_root):
        dirnames[:] = [d for d in dirnames if d not in skip_dir_parts]
        for name in filenames:
            if not name.endswith(".md"):
                continue
            path = Path(dirpath) / name
            rel = path.relative_to(scan_root).as_posix()
            text = path.read_text(encoding="utf-8")
            for match in link_re.finditer(text):
                raw = match.group(1).strip()
                url = raw.split()[0] if raw else ""
                url = url.strip("<>")
                if not url or url.startswith("#"):
                    continue
                if re.match(r"^(https?|mailto|data|tel):", url, re.I):
                    continue
                path_part = url.split("#", 1)[0]
                if not path_part:
                    continue
                target = (path.parent / path_part).resolve()
                if not target.exists():
                    broken.append((rel, url))
    return broken


tmpdir = Path(tempfile.mkdtemp(prefix="md-rel-links-"))
try:
    good = tmpdir / "good"
    good.mkdir()
    (good / "present.md").write_text("# present\n", encoding="utf-8")
    (good / "README.md").write_text(
        "See [present](./present.md) and [sibling](present.md#frag).\n",
        encoding="utf-8",
    )

    bad = tmpdir / "bad"
    bad.mkdir()
    (bad / "README.md").write_text("See [missing](./nope.md).\n", encoding="utf-8")

    good_broken = broken_links(good)
    if good_broken:
        print("error: self-test good tree unexpectedly broken:", file=sys.stderr)
        for src, url in good_broken:
            print(f"  {src} -> {url}", file=sys.stderr)
        sys.exit(1)

    bad_broken = broken_links(bad)
    if not bad_broken:
        print(
            "error: self-test bad tree should report broken relative links",
            file=sys.stderr,
        )
        sys.exit(1)
    if not any(url.endswith("nope.md") for _, url in bad_broken):
        print(f"error: self-test expected nope.md; got {bad_broken}", file=sys.stderr)
        sys.exit(1)

    # Intentionally broken fixture under fixtures/ must be ignored by skip rule.
    fixtures = tmpdir / "tool" / "fixtures" / "markdown_relative_links"
    fixtures.mkdir(parents=True)
    (fixtures / "broken.md").write_text("[x](./ghost.md)\n", encoding="utf-8")
    # Walk from tmpdir/tool so fixtures/ is a dir name on the path.
    ignored = broken_links(tmpdir / "tool")
    if ignored:
        print(
            "error: self-test must skip tool/fixtures broken hrefs; "
            f"got {ignored}",
            file=sys.stderr,
        )
        sys.exit(1)

    print("ok: Markdown relative-link self-test passed")
finally:
    shutil.rmtree(tmpdir, ignore_errors=True)
PY
    exit 0
    ;;
  "")
    ;;
  *)
    echo "error: unknown option: $1" >&2
    usage >&2
    exit 2
    ;;
esac

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
    # Intentional broken/good samples for gate self-tests.
    "fixtures",
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
