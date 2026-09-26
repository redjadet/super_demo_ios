#!/usr/bin/env bash
# Fail when Swift sources use 2-space member indentation (common agent/IDE mistake).
# Repo standard: 4 spaces — .editorconfig, .swiftformat, SwiftFormat lint in ./bin/lint.sh.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"

# Member-level keywords at exactly two spaces (not four).
PATTERN='^  (func |init\(|var |let |case |private |fileprivate |internal |public |@Test|@Suite|@MainActor)'

failed=0
while IFS= read -r -d '' file; do
  hits="$(grep -En "$PATTERN" "$file" 2>/dev/null | head -5 || true)"
  if [[ -n "$hits" ]]; then
    echo "error: $file uses 2-space member indentation (expected 4)." >&2
    echo "$hits" | sed 's/^/  /' >&2
    local_extra=""
    if [[ "$(grep -cE "$PATTERN" "$file" 2>/dev/null || echo 0)" -gt 5 ]]; then
      local_extra="  …and more lines in this file"
    fi
    [[ -n "$local_extra" ]] && echo "$local_extra" >&2
    echo "  Fix: ./bin/verify-swift.sh  (or ./bin/format.sh then ./bin/lint.sh)" >&2
    failed=1
  fi
done < <(
  find "$ROOT/superDemoApp" "$ROOT/FeedWidgetShared" "$ROOT/superDemoAppWidget" \
    "$ROOT/ShareInboxShared" "$ROOT/superDemoAppShare" \
    "$ROOT/superDemoAppTests" "$ROOT/superDemoAppUITests" \
    -name '*.swift' -print0
)

if [[ "$failed" -ne 0 ]]; then
  echo "See docs/agent_swift_guards.md" >&2
  exit 1
fi
