#!/usr/bin/env bash
# Local CI parity: lint, iPhone test, iPad/Mac builds (matches .github/workflows/ci.yml).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

export PATH="/opt/homebrew/bin:/usr/local/bin:${PATH}"
export CI=true

if [[ "${CI:-}" == "true" && -z "${CI_SIMULATOR_DEST:-}" ]]; then
  ./tool/ensure_ci_simulator.sh
fi

# shellcheck source=../tool/resolve_platform_destination.sh
source "$ROOT/tool/resolve_platform_destination.sh"
# shellcheck source=../tool/xcodebuild_sandbox_flags.sh
source "$ROOT/tool/xcodebuild_sandbox_flags.sh"

SIMULATOR_DEST="$(resolve_iphone_destination)"
echo "==> iPhone destination: $SIMULATOR_DEST"

TEST_SERIAL_FLAGS=()
if [[ "${CI_ALLOW_PARALLEL_TESTS:-0}" != "1" ]]; then
  TEST_SERIAL_FLAGS=(
    -parallel-testing-enabled NO
    -parallel-testing-worker-count 1
    -maximum-parallel-testing-workers 1
    -maximum-concurrent-test-simulator-destinations 1
    -maximum-concurrent-test-device-destinations 1
  )
fi

echo "==> Swift lint"
./bin/lint.sh

echo "==> Markdown lint"
./bin/lint-markdown.sh

echo "==> Common issue checks"
./tool/check_common_issues.sh

echo "==> iPhone tests (builds app + tests)"
xcodebuild \
  -project superDemoApp.xcodeproj \
  -scheme superDemoApp \
  -destination "$SIMULATOR_DEST" \
  -configuration Debug \
  "${XCODEBUILD_SANDBOX_FLAGS[@]}" \
  "${TEST_SERIAL_FLAGS[@]}" \
  test

if [[ "${CI_SKIP_PLATFORM_BUILDS:-0}" != "1" ]]; then
  ./bin/ci-platform-builds.sh
else
  echo "info: skipping iPad/Mac builds because CI_SKIP_PLATFORM_BUILDS=1"
fi

echo "CI checks passed."
