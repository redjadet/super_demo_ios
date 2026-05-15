#!/usr/bin/env bash
# Lint superDemoApp — SwiftLint (strict) + SwiftFormat (lint mode).
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

echo "==> SwiftLint"
swiftlint lint --strict --config "$ROOT/.swiftlint.yml"

echo "==> SwiftFormat (lint)"
swiftformat --lint "$ROOT/superDemoApp" "$ROOT/superDemoAppTests" "$ROOT/superDemoAppUITests"

echo "==> Layer boundaries (Features/*)"
"$ROOT/tool/check_layer_boundaries.sh"

echo "Lint passed."
