#!/usr/bin/env bash
# After Brewfile install: sync SwiftFormat to tool/expected_tool_versions.sh.
# brew bundle check only asserts "some" swiftformat is present — runners with
# HOMEBREW_NO_AUTO_UPDATE can keep an older bottle and fail the pin gate in
# Checklist · lint vs Checklist · iPhone build inconsistently.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck source=expected_tool_versions.sh
source "$ROOT/tool/expected_tool_versions.sh"

export PATH="/opt/homebrew/bin:/usr/local/bin:${PATH}"

if ! command -v brew >/dev/null 2>&1; then
  echo "error: brew not found (required to sync SwiftFormat pin)" >&2
  exit 1
fi

if ! command -v swiftformat >/dev/null 2>&1; then
  echo "==> swiftformat missing — brew install"
  brew install swiftformat
fi

actual="$(swiftformat --version | tr -d '[:space:]')"
if [[ "$actual" == "$EXPECTED_SWIFTFORMAT_VERSION" ]]; then
  echo "==> SwiftFormat pin ok: ${actual}"
  exit 0
fi

echo "==> SwiftFormat ${actual} != pin ${EXPECTED_SWIFTFORMAT_VERSION}; refreshing Homebrew + upgrading"
# CI sets HOMEBREW_NO_AUTO_UPDATE=1 — refresh formula so upgrade can see the pin.
brew update --quiet
brew upgrade swiftformat || brew reinstall swiftformat

actual="$(swiftformat --version | tr -d '[:space:]')"
if [[ "$actual" != "$EXPECTED_SWIFTFORMAT_VERSION" ]]; then
  echo "error: SwiftFormat ${EXPECTED_SWIFTFORMAT_VERSION} required after brew sync, got ${actual}" >&2
  echo "hint: bump tool/expected_tool_versions.sh (+ Brewfile comment) to match Homebrew," >&2
  echo "hint: or wait for runners to pick up the formula bottle for ${EXPECTED_SWIFTFORMAT_VERSION}" >&2
  exit 1
fi

echo "==> SwiftFormat pin synced: ${actual}"
"$ROOT/tool/check_swiftformat_version.sh"
