#!/usr/bin/env bash
# Format superDemoApp sources in place.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

require() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "error: $1 not found. Install: brew bundle --file Brewfile" >&2
    exit 1
  fi
}

require swiftlint
require swiftformat

echo "==> SwiftFormat version pin"
"$ROOT/tool/check_swiftformat_version.sh"

echo "==> SwiftFormat"
swiftformat \
  --config "$ROOT/.swiftformat" \
  "$ROOT/superDemoApp" \
  "$ROOT/FeedWidgetShared" \
  "$ROOT/superDemoAppWidget" \
  "$ROOT/superDemoAppTests" \
  "$ROOT/superDemoAppUITests"

echo "Format complete. Run ./bin/verify-swift.sh (format + lint) before committing."
echo "Agents: docs/agent_swift_guards.md — indent, braces, @MainActor deinit, UIKit teardown."
