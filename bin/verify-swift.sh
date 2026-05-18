#!/usr/bin/env bash
# Single Swift gate for agents: format in place, then lint (indent, SwiftLint, SwiftFormat, patterns).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

echo "==> Swift verify (format + lint)"
"$ROOT/bin/format.sh"
"$ROOT/bin/lint.sh"
echo "Swift verify passed."
