#!/usr/bin/env bash
# Fail when installed SwiftFormat drifts from the repo pin (local + CI parity).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck source=expected_tool_versions.sh
source "$ROOT/tool/expected_tool_versions.sh"

if ! command -v swiftformat >/dev/null 2>&1; then
  echo "error: swiftformat not found. Install: brew bundle --file Brewfile" >&2
  exit 1
fi

actual="$(swiftformat --version | tr -d '[:space:]')"
if [[ "$actual" != "$EXPECTED_SWIFTFORMAT_VERSION" ]]; then
  echo "error: SwiftFormat ${EXPECTED_SWIFTFORMAT_VERSION} required, got ${actual}" >&2
  echo "hint: brew upgrade swiftformat  # or brew install swiftformat@${EXPECTED_SWIFTFORMAT_VERSION} if available" >&2
  echo "hint: keep Brewfile + tool/expected_tool_versions.sh in sync" >&2
  exit 1
fi
