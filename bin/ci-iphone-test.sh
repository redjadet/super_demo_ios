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

XCODEBUILD_TEST_ARGS=(
  -project superDemoApp.xcodeproj
  -scheme superDemoApp
  -destination "$SIMULATOR_DEST"
  -configuration Debug
  ${IPHONE_DERIVED_DATA_PATH+-derivedDataPath "$IPHONE_DERIVED_DATA_PATH"}
  ${XCODEBUILD_SANDBOX_FLAGS+"${XCODEBUILD_SANDBOX_FLAGS[@]}"}
  ${TEST_SERIAL_FLAGS+"${TEST_SERIAL_FLAGS[@]}"}
)

echo "==> iPhone tests (builds app + tests, $XCODEBUILD)"
log_dir="$(mktemp -d)"
trap 'rm -rf "$log_dir"' EXIT
test_log="$log_dir/iphone-test.log"

run_xcodebuild_with_ci_timeout() {
  assert_xcodebuild_matches_developer_dir || return 1
  if [[ "${CI:-}" == "true" ]]; then
    python3 "$ROOT/tool/run_with_timeout.py" \
      --timeout "${CI_IPHONE_XCODEBUILD_TIMEOUT_SECONDS:-900}" \
      -- "$XCODEBUILD" "$@"
  else
    "$XCODEBUILD" "$@"
  fi
}

run_tests() {
  run_xcodebuild_with_ci_timeout \
    "${XCODEBUILD_TEST_ARGS[@]}" \
    test 2>&1 | tee "$test_log"
}

test_status=0
run_tests || test_status=$?
if ((test_status == 0)); then
  exit 0
fi

if [[ "${CI:-}" == "true" ]] && {
  ((test_status == 124)) || grep -q "Timed out while loading Accessibility" "$test_log"
}; then
  echo "warning: UI test runner failed or timed out; retrying once after simulator reboot" >&2

  udid="$(sed -n 's/.*id=\([0-9A-F-]\{36\}\).*/\1/p' <<<"$SIMULATOR_DEST")"
  if [[ "$udid" =~ ^[0-9A-F-]{36}$ ]]; then
    xcrun simctl shutdown "$udid" 2>/dev/null || true
    xcrun simctl boot "$udid" 2>/dev/null || true
    xcrun simctl bootstatus "$udid" -b 2>/dev/null || true
  fi

  run_tests || exit $?
fi

exit "$test_status"
