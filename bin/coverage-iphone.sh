#!/usr/bin/env bash
# Optional local / nightly code-coverage measurement (NOT a PR gate).
# Runs xcodebuild test with -enableCodeCoverage YES and prints the .xcresult
# path for inspection. Does not invent a % or update README badges.
#
# Usage (from repo root):
#   ./bin/coverage-iphone.sh
# Env:
#   CI_SIMULATOR_DEST / resolve_iphone_destination — same as ci-iphone-test
#   IPHONE_DERIVED_DATA_PATH — optional DerivedData path
#   COVERAGE_RESULT_BUNDLE — optional explicit .xcresult path
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

if [[ "${CI:-}" == "true" ]]; then
  # shellcheck source=../tool/select_xcode.sh
  source "$ROOT/tool/select_xcode.sh"
else
  export PATH="/opt/homebrew/bin:/usr/local/bin:${PATH}"
fi

# shellcheck source=../tool/xcode_env.sh
source "$ROOT/tool/xcode_env.sh"
# shellcheck source=../tool/resolve_platform_destination.sh
source "$ROOT/tool/resolve_platform_destination.sh"
# shellcheck source=../tool/xcodebuild_sandbox_flags.sh
source "$ROOT/tool/xcodebuild_sandbox_flags.sh"
# shellcheck source=../tool/xcode_warnings_as_errors_flags.sh
source "$ROOT/tool/xcode_warnings_as_errors_flags.sh"

./tool/check_simulator_runtime_compat.sh

if [[ "${CI:-}" == "true" && -z "${CI_SIMULATOR_DEST:-}" ]]; then
  CI_PREPARE_IPAD="${CI_PREPARE_IPAD:-0}" source "$ROOT/tool/ensure_ci_simulator.sh" || exit $?
fi

SIMULATOR_DEST="$(resolve_iphone_destination)"
RESULT_BUNDLE="${COVERAGE_RESULT_BUNDLE:-$ROOT/build/coverage-iphone.xcresult}"
rm -rf "$RESULT_BUNDLE"
mkdir -p "$(dirname "$RESULT_BUNDLE")"

echo "==> Coverage iPhone destination: $SIMULATOR_DEST"
echo "==> Result bundle: $RESULT_BUNDLE"
echo "==> Honesty: this is measurement only — do not invent a README % badge."

# shellcheck disable=SC2086
"$XCODEBUILD" test \
  -project superDemoApp.xcodeproj \
  -scheme superDemoApp \
  -destination "$SIMULATOR_DEST" \
  -configuration Debug \
  -enableCodeCoverage YES \
  -resultBundlePath "$RESULT_BUNDLE" \
  ${IPHONE_DERIVED_DATA_PATH+-derivedDataPath "$IPHONE_DERIVED_DATA_PATH"} \
  ${XCODEBUILD_SANDBOX_FLAGS+"${XCODEBUILD_SANDBOX_FLAGS[@]}"} \
  ${XCODEBUILD_WARNINGS_AS_ERRORS_FLAGS+"${XCODEBUILD_WARNINGS_AS_ERRORS_FLAGS[@]}"} \
  -parallel-testing-enabled NO

echo
echo "Coverage result bundle ready:"
echo "  $RESULT_BUNDLE"
echo "Inspect: open in Xcode Organizer, or:"
echo "  xcrun xccov view --report \"$RESULT_BUNDLE\""
echo "Do not publish a shields.io coverage badge until a named filtered summary"
echo "artifact exists and docs/code-quality.md + a change note allow it."
