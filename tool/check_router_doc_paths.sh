#!/usr/bin/env bash
# Fail when cold-path router docs still use abbreviated App/Shared/Features
# paths that only resolve under superDemoApp/ (post-#40 CODEMAP honesty).
#
# Usage:
#   ./tool/check_router_doc_paths.sh
#   ./tool/check_router_doc_paths.sh --self-test
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

usage() {
  sed -n '2,8p' "$0" | sed 's/^# \{0,1\}//'
}

case "${1:-}" in
  -h|--help|help)
    usage
    exit 0
    ;;
  --self-test)
    echo "==> Router doc path self-test (fixtures)"
    python3 - <<'PY'
from __future__ import annotations

import re
import sys
import tempfile
from pathlib import Path

TICK = re.compile(r"`([^`\n]+)`")
PREFIXES = ("App/", "Shared/", "Features/")


def abbreviated(text: str) -> list[str]:
    hits: list[str] = []
    for match in TICK.finditer(text):
        inner = match.group(1).strip()
        if inner.startswith("superDemoApp/"):
            continue
        if any(inner.startswith(p) for p in PREFIXES):
            hits.append(inner)
    return hits


tmpdir = Path(tempfile.mkdtemp(prefix="router-paths-"))
try:
    bad = tmpdir / "bad.md"
    bad.write_text("See `Features/Feed/` and `superDemoApp/Shared/Networking/`.\n", encoding="utf-8")
    good = tmpdir / "good.md"
    good.write_text("See `superDemoApp/Features/Feed/` only.\n", encoding="utf-8")
    assert abbreviated(bad.read_text(encoding="utf-8")) == ["Features/Feed/"]
    assert abbreviated(good.read_text(encoding="utf-8")) == []
    print("ok: router doc path self-test passed")
finally:
    import shutil

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

import re
import sys
from pathlib import Path

TICK = re.compile(r"`([^`\n]+)`")
PREFIXES = ("App/", "Shared/", "Features/")
ROUTER_DOCS = (
    Path("CODEMAP.md"),
    Path("docs/portfolio.md"),
    Path("docs/architecture-tour.md"),
)

failures: list[str] = []
for doc in ROUTER_DOCS:
    if not doc.is_file():
        failures.append(f"missing router doc: {doc}")
        continue
    text = doc.read_text(encoding="utf-8")
    for match in TICK.finditer(text):
        inner = match.group(1).strip()
        if inner.startswith("superDemoApp/"):
            continue
        if "*" in inner or "<" in inner or "…" in inner:
            # Still require the superDemoApp/ prefix on abbreviated roots.
            root = inner.split("*", 1)[0].split("<", 1)[0].split("…", 1)[0]
            if any(root.startswith(p) or inner.startswith(p) for p in PREFIXES):
                if not inner.startswith("superDemoApp/"):
                    failures.append(f"{doc}: abbreviated path `{inner}` (use superDemoApp/…)")
            continue
        if any(inner.startswith(p) for p in PREFIXES):
            failures.append(f"{doc}: abbreviated path `{inner}` (use superDemoApp/…)")

# Workspace-layout honesty: tests live at repo root, not under nested app sources.
ctx = Path("docs/agent_project_context.md")
if ctx.is_file():
    text = ctx.read_text(encoding="utf-8")
    for bad in (
        "superDemoApp/superDemoAppTests/",
        "superDemoApp/superDemoAppUITests/",
    ):
        if f"`{bad}`" in text:
            failures.append(
                f"{ctx}: `{bad}` does not exist — use repo-root "
                f"`{bad.removeprefix('superDemoApp/')}`"
            )

if failures:
    print("Router doc path check failed:", file=sys.stderr)
    for item in failures:
        print(f"  - {item}", file=sys.stderr)
    sys.exit(1)

print("Router doc paths OK (CODEMAP + portfolio + architecture-tour; workspace tests).")
PY
