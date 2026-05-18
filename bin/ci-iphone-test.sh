#!/usr/bin/env bash
# iPhone build/test proof lane used by local CI and GitHub Actions.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

if [[ "${CI:-}" == "true" ]]; then
  # shellcheck source=../tool/select_xcode_26_5.sh
  source "$ROOT/tool/select_xcode_26_5.sh"
else
  export PATH="/opt/homebrew/bin:/usr/local/bin:${PATH}"
fi

# shellcheck source=../tool/xcode_env.sh
source "$ROOT/tool/xcode_env.sh"

if [[ "${CI:-}" == "true" && -z "${CI_SIMULATOR_DEST:-}" ]]; then
  CI_PREPARE_IPAD="${CI_PREPARE_IPAD:-0}" source "$ROOT/tool/ensure_ci_simulator.sh" || exit $?
fi

# shellcheck source=../tool/resolve_platform_destination.sh
source "$ROOT/tool/resolve_platform_destination.sh"
# shellcheck source=../tool/xcodebuild_sandbox_flags.sh
source "$ROOT/tool/xcodebuild_sandbox_flags.sh"

SIMULATOR_DEST="$(resolve_iphone_destination)"
echo "==> iPhone destination: $SIMULATOR_DEST"

if [[ "${CI_ALLOW_PARALLEL_TESTS:-0}" != "1" ]]; then
  TEST_SERIAL_FLAGS=(
    -parallel-testing-enabled NO
    -parallel-testing-worker-count 1
    -maximum-parallel-testing-workers 1
    -maximum-concurrent-test-simulator-destinations 1
    -maximum-concurrent-test-device-destinations 1
  )
fi

assert_xcodebuild_matches_developer_dir
echo "==> iPhone tests (builds app + tests, $XCODEBUILD)"
env DEVELOPER_DIR="$DEVELOPER_DIR" "$XCODEBUILD" \
  -project superDemoApp.xcodeproj \
  -scheme superDemoApp \
  -destination "$SIMULATOR_DEST" \
  -configuration Debug \
  ${XCODEBUILD_SANDBOX_FLAGS+"${XCODEBUILD_SANDBOX_FLAGS[@]}"} \
  ${TEST_SERIAL_FLAGS+"${TEST_SERIAL_FLAGS[@]}"} \
  test
