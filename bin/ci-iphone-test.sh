#!/usr/bin/env bash
# iPhone build/test proof lane used by local CI and GitHub Actions.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

export PATH="/opt/homebrew/bin:/usr/local/bin:${PATH}"

if [[ "${CI:-}" == "true" && -z "${CI_SIMULATOR_DEST:-}" ]]; then
  ./tool/ensure_ci_simulator.sh
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

echo "==> iPhone tests (builds app + tests)"
xcodebuild \
  -project superDemoApp.xcodeproj \
  -scheme superDemoApp \
  -destination "$SIMULATOR_DEST" \
  -configuration Debug \
  ${XCODEBUILD_SANDBOX_FLAGS+"${XCODEBUILD_SANDBOX_FLAGS[@]}"} \
  ${TEST_SERIAL_FLAGS+"${TEST_SERIAL_FLAGS[@]}"} \
  test
