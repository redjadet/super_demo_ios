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

echo "==> SwiftFormat version pin"
"$ROOT/tool/check_swiftformat_version.sh"

echo "==> Swift indent (4 spaces)"
"$ROOT/tool/check_swift_two_space_indent.sh"

echo "==> Agent Swift patterns"
"$ROOT/tool/check_agent_swift_patterns.sh"

echo "==> SwiftLint"
swiftlint lint --strict --config "$ROOT/.swiftlint.yml"

echo "==> SwiftFormat (lint)"
if ! swiftformat \
  --lint \
  --config "$ROOT/.swiftformat" \
  "$ROOT/superDemoApp" \
  "$ROOT/superDemoAppTests" \
  "$ROOT/superDemoAppUITests"
then
  echo "hint: run ./bin/format.sh to fix indentation and wrapping, then ./bin/lint.sh again" >&2
  exit 1
fi

echo "==> Layer boundaries (Features/*)"
"$ROOT/tool/check_layer_boundaries.sh"

echo "==> Feature folder contract"
"$ROOT/tool/check_feature_folder_contract.sh"

echo "==> Cross-feature import leaks"
"$ROOT/tool/check_feature_import_leaks.sh"

echo "==> Engineering quality scorecard"
"$ROOT/tool/check_engineering_quality_scorecard.sh"

echo "Lint passed."
