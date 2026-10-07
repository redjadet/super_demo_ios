#!/usr/bin/env bash
# iPhone build/test proof lane used by local CI and GitHub Actions.
# On CI, prefers a concrete newest-runtime iPhone simulator and runs xcodebuild test
# (set CI_IPHONE_GENERIC_BUILD=1 to keep the legacy build-only generic destination).
#
# Hosted shards may set:
#   CI_IPHONE_TEST_MODE=test-without-building
#   CI_IPHONE_PRODUCTS_DIR=.../Build/Products
#   CI_IPHONE_TEST_SHARD=unit|ui-a|ui-b (legacy: unit-and-app-ui|engineering-a|engineering-b)
#   CI_ALLOW_PARALLEL_TESTS=1 + CI_PARALLEL_TESTING_WORKER_COUNT=2|3
#   CI_SIMULATOR_REUSE_ONLY=1 — never create/erase simulators
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
# shellcheck source=../tool/ci_iphone_test_shards.sh
source "$ROOT/tool/ci_iphone_test_shards.sh"

# Hosted PR default: run real simulator tests on the newest available iPhone.
# Escape hatch for runner images without a usable Simulator platform:
#   CI_IPHONE_GENERIC_BUILD=1
CI_IPHONE_GENERIC_BUILD="${CI_IPHONE_GENERIC_BUILD:-0}"
CI_IPHONE_TEST_MODE="${CI_IPHONE_TEST_MODE:-test}"
CI_IPHONE_TEST_SHARD="${CI_IPHONE_TEST_SHARD:-}"
CI_SIMULATOR_REUSE_ONLY="${CI_SIMULATOR_REUSE_ONLY:-1}"

echo "==> Simulator runtime ↔ device-type compat (before xcodebuild)"
./tool/check_simulator_runtime_compat.sh

if [[ "${CI:-}" == "true" && "${CI_IPHONE_GENERIC_BUILD}" != "1" && -z "${CI_SIMULATOR_DEST:-}" ]]; then
  if [[ "${CI_SIMULATOR_REUSE_ONLY}" == "1" ]]; then
    # shellcheck source=../tool/ci_simulator_pick_existing.sh
    source "$ROOT/tool/ci_simulator_pick_existing.sh" || exit $?
  else
    CI_PREPARE_IPAD="${CI_PREPARE_IPAD:-0}" source "$ROOT/tool/ensure_ci_simulator.sh" || exit $?
  fi
fi

# shellcheck source=../tool/resolve_platform_destination.sh
source "$ROOT/tool/resolve_platform_destination.sh"
# shellcheck source=../tool/xcodebuild_sandbox_flags.sh
source "$ROOT/tool/xcodebuild_sandbox_flags.sh"
# shellcheck source=../tool/xcode_warnings_as_errors_flags.sh
source "$ROOT/tool/xcode_warnings_as_errors_flags.sh"

if [[ "${CI:-}" == "true" && "${CI_IPHONE_GENERIC_BUILD}" == "1" ]]; then
  SIMULATOR_DEST="${CI_IPHONE_BUILD_DEST:-generic/platform=iOS Simulator}"
elif [[ -n "${CI_SIMULATOR_DEST:-}" ]]; then
  SIMULATOR_DEST="$CI_SIMULATOR_DEST"
else
  SIMULATOR_DEST="$(resolve_iphone_destination)"
fi
echo "==> iPhone destination: $SIMULATOR_DEST"
if [[ -n "$CI_IPHONE_TEST_SHARD" ]]; then
  echo "==> iPhone test shard: $CI_IPHONE_TEST_SHARD"
fi
echo "==> iPhone test mode: $CI_IPHONE_TEST_MODE"

TEST_SERIAL_FLAGS=()
if [[ "${CI_ALLOW_PARALLEL_TESTS:-0}" == "1" ]]; then
  workers="${CI_PARALLEL_TESTING_WORKER_COUNT:-2}"
  echo "==> Parallel testing enabled (workers=${workers})"
  TEST_SERIAL_FLAGS=(
    -parallel-testing-enabled YES
    -parallel-testing-worker-count "$workers"
    -maximum-parallel-testing-workers "$workers"
  )
else
  TEST_SERIAL_FLAGS=(
    -parallel-testing-enabled NO
    -parallel-testing-worker-count 1
    -maximum-parallel-testing-workers 1
    -maximum-concurrent-test-simulator-destinations 1
    -maximum-concurrent-test-device-destinations 1
  )
fi

ONLY_TESTING_FLAGS=()
while IFS= read -r flag; do
  [[ -z "$flag" ]] && continue
  ONLY_TESTING_FLAGS+=("$flag")
done < <(ci_iphone_shard_only_testing_args "$CI_IPHONE_TEST_SHARD")

XCODEBUILD_TEST_ARGS=(
  -destination "$SIMULATOR_DEST"
  -configuration Debug
  ${XCODEBUILD_SANDBOX_FLAGS+"${XCODEBUILD_SANDBOX_FLAGS[@]}"}
  ${XCODEBUILD_WARNINGS_AS_ERRORS_FLAGS+"${XCODEBUILD_WARNINGS_AS_ERRORS_FLAGS[@]}"}
  ${TEST_SERIAL_FLAGS+"${TEST_SERIAL_FLAGS[@]}"}
  ${ONLY_TESTING_FLAGS+"${ONLY_TESTING_FLAGS[@]}"}
)

XCODEBUILD_BUILD_ARGS=(
  -project superDemoApp.xcodeproj
  -scheme superDemoApp
  -destination "$SIMULATOR_DEST"
  -configuration Debug
  ${IPHONE_DERIVED_DATA_PATH+-derivedDataPath "$IPHONE_DERIVED_DATA_PATH"}
  ${XCODEBUILD_SANDBOX_FLAGS+"${XCODEBUILD_SANDBOX_FLAGS[@]}"}
  ${XCODEBUILD_WARNINGS_AS_ERRORS_FLAGS+"${XCODEBUILD_WARNINGS_AS_ERRORS_FLAGS[@]}"}
)

ci_has_ios_simulator_destination() {
  assert_xcodebuild_matches_developer_dir || return 1
  "$XCODEBUILD" \
    -project superDemoApp.xcodeproj \
    -scheme superDemoApp \
    -showdestinations 2>&1 \
    | grep -q 'platform:iOS Simulator'
}

resolve_xctestrun_path() {
  if [[ -n "${CI_XCTESTRUN_PATH:-}" && -f "${CI_XCTESTRUN_PATH}" ]]; then
    printf '%s\n' "$CI_XCTESTRUN_PATH"
    return 0
  fi
  local products="${CI_IPHONE_PRODUCTS_DIR:-}"
  if [[ -z "$products" && -n "${IPHONE_DERIVED_DATA_PATH:-}" ]]; then
    products="$IPHONE_DERIVED_DATA_PATH/Build/Products"
  fi
  if [[ -z "$products" || ! -d "$products" ]]; then
    echo "error: CI_IPHONE_PRODUCTS_DIR (or IPHONE_DERIVED_DATA_PATH/Build/Products) required for test-without-building" >&2
    return 1
  fi
  if [[ -f "$products/ci-iphone-build-metadata.env" ]]; then
    # shellcheck disable=SC1090
    source "$products/ci-iphone-build-metadata.env"
    if [[ -n "${XCTESTRUN_BASENAME:-}" && -f "$products/$XCTESTRUN_BASENAME" ]]; then
      printf '%s\n' "$products/$XCTESTRUN_BASENAME"
      return 0
    fi
  fi
  local found
  found="$(find "$products" -maxdepth 1 -name '*.xctestrun' | sort | head -n 1)"
  if [[ -z "$found" ]]; then
    echo "error: no .xctestrun in $products" >&2
    return 1
  fi
  printf '%s\n' "$found"
}

if [[ "${CI:-}" == "true" && "${CI_IPHONE_GENERIC_BUILD}" == "1" ]]; then
  if ! ci_has_ios_simulator_destination; then
    echo "warning: iOS Simulator platform unavailable on this GitHub runner; skipping iPhone build sanity" >&2
    exit 0
  fi

  echo "==> iPhone build sanity ($XCODEBUILD) [CI_IPHONE_GENERIC_BUILD=1]"
  assert_xcodebuild_matches_developer_dir
  python3 "$ROOT/tool/run_with_timeout.py" \
    --timeout "${CI_IPHONE_XCODEBUILD_TIMEOUT_SECONDS:-900}" \
    -- "$XCODEBUILD" \
    "${XCODEBUILD_BUILD_ARGS[@]}" \
    build
  exit 0
fi

log_dir="$(mktemp -d)"
trap 'rm -rf "$log_dir"' EXIT
test_log="$log_dir/iphone-test.log"

# Hosted runners: skip the XCTest performance case (long/noisy) and never retry a
# hard xcodebuild timeout — a second full suite can starve the runner (lost comms).
TEST_SELECTION_FLAGS=("${TEST_SELECTION_FLAGS[@]+"${TEST_SELECTION_FLAGS[@]}"}")
if [[ "${CI:-}" == "true" ]]; then
  TEST_SELECTION_FLAGS+=(
    -skip-testing:superDemoAppUITests/superDemoAppUITests/testLaunchPerformance
  )
fi

run_xcodebuild_with_ci_timeout() {
  assert_xcodebuild_matches_developer_dir || return 1
  if [[ "${CI:-}" == "true" ]]; then
    python3 "$ROOT/tool/run_with_timeout.py" \
      --timeout "${CI_IPHONE_XCODEBUILD_TIMEOUT_SECONDS:-1800}" \
      -- "$XCODEBUILD" "$@"
  else
    "$XCODEBUILD" "$@"
  fi
}

run_tests() {
  # Preserve xcodebuild/timeout status through tee (pipefail alone uses last cmd).
  set +e
  if [[ "$CI_IPHONE_TEST_MODE" == "test-without-building" ]]; then
    local xctestrun
    xctestrun="$(resolve_xctestrun_path)" || return 1
    echo "==> iPhone test-without-building ($XCODEBUILD) xctestrun=$xctestrun"
    run_xcodebuild_with_ci_timeout \
      -xctestrun "$xctestrun" \
      "${XCODEBUILD_TEST_ARGS[@]}" \
      ${TEST_SELECTION_FLAGS+"${TEST_SELECTION_FLAGS[@]}"} \
      test-without-building 2>&1 | tee "$test_log"
  else
    echo "==> iPhone tests (builds app + tests, $XCODEBUILD)"
    run_xcodebuild_with_ci_timeout \
      -project superDemoApp.xcodeproj \
      -scheme superDemoApp \
      ${IPHONE_DERIVED_DATA_PATH+-derivedDataPath "$IPHONE_DERIVED_DATA_PATH"} \
      "${XCODEBUILD_TEST_ARGS[@]}" \
      ${TEST_SELECTION_FLAGS+"${TEST_SELECTION_FLAGS[@]}"} \
      test 2>&1 | tee "$test_log"
  fi
  local status=${PIPESTATUS[0]}
  set -e
  return "$status"
}

test_status=0
run_tests || test_status=$?
if ((test_status == 0)); then
  exit 0
fi

if ((test_status == 124)); then
  echo "error: iPhone xcodebuild timed out (no full-suite retry on hard timeout)" >&2
  exit 124
fi

# Accessibility / launch-progress / UI-query flakes — reboot simulator once, then retry.
# (Hard xcodebuild 124 timeouts still do not retry — see above.)
if [[ "${CI:-}" == "true" ]] && grep -Eq \
  "Timed out while loading Accessibility|Timed out while requesting launch progress|Timed out while evaluating UI query" \
  "$test_log"
then
  echo "warning: UI test Accessibility/launch-progress/UI-query timeout; retrying once after simulator reboot" >&2

  udid="$(sed -n 's/.*id=\([0-9A-Fa-f-]\{36\}\).*/\1/p' <<<"$SIMULATOR_DEST" | tr '[:lower:]' '[:upper:]')"
  if [[ "$udid" =~ ^[0-9A-F-]{36}$ ]]; then
    xcrun simctl shutdown "$udid" 2>/dev/null || true
    xcrun simctl boot "$udid" 2>/dev/null || true
    xcrun simctl bootstatus "$udid" -b 2>/dev/null || true
  fi

  run_tests || exit $?
  exit 0
fi

exit "$test_status"
