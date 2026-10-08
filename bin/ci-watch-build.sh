#!/usr/bin/env bash
# watchOS Simulator: compile proof + Feed companion integration tests.
# Used by ci-platform-builds.sh.
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
# shellcheck source=../tool/xcodebuild_sandbox_flags.sh
source "$ROOT/tool/xcodebuild_sandbox_flags.sh"
# shellcheck source=../tool/xcode_warnings_as_errors_flags.sh
source "$ROOT/tool/xcode_warnings_as_errors_flags.sh"

assert_xcodebuild_matches_developer_dir || exit 1

ci_has_watch_simulator_destination() {
  "$XCODEBUILD" \
    -project superDemoApp.xcodeproj \
    -scheme superDemoAppWatch \
    -showdestinations 2>&1 \
    | grep -q 'platform:watchOS Simulator'
}

if [[ "${CI:-}" == "true" ]] && ! ci_has_watch_simulator_destination; then
  echo "warning: watchOS Simulator platform unavailable on this GitHub runner; skipping watch build/tests" >&2
  exit 0
fi

resolve_watch_test_destination() {
  if [[ -n "${CI_WATCH_BUILD_DEST:-}" ]]; then
    printf '%s\n' "$CI_WATCH_BUILD_DEST"
    return 0
  fi
  local line id name
  line="$("$XCODEBUILD" -project superDemoApp.xcodeproj -scheme superDemoAppWatch -showdestinations 2>/dev/null \
    | grep 'platform:watchOS Simulator' \
    | grep -v 'placeholder' \
    | grep 'id:' \
    | head -1 || true)"
  if [[ -n "$line" ]]; then
    id="$(sed -n 's/.*id:\([^,}]*\).*/\1/p' <<<"$line" | tr -d ' ')"
    name="$(sed -n 's/.*name:\([^}]*\).*/\1/p' <<<"$line" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
    if [[ -n "$id" && "$id" != *placeholder* ]]; then
      printf 'platform=watchOS Simulator,id=%s\n' "$id"
      return 0
    fi
    if [[ -n "$name" ]]; then
      printf 'platform=watchOS Simulator,name=%s\n' "$name"
      return 0
    fi
  fi
  # Fall back: prefer a concrete Series 12 sim when present.
  id="$(xcrun simctl list devices available 2>/dev/null \
    | grep -E 'Apple Watch Series 12 \(46mm\)' \
    | head -1 \
    | sed -n 's/.*(\([A-F0-9-]\{36\}\)).*/\1/p' || true)"
  if [[ -n "$id" ]]; then
    printf 'platform=watchOS Simulator,id=%s\n' "$id"
    return 0
  fi
  printf '%s\n' "generic/platform=watchOS Simulator"
}

WATCH_DEST="$(resolve_watch_test_destination)"
echo "==> watchOS destination: $WATCH_DEST"

if [[ -n "${WATCH_DERIVED_DATA_PATH:-}" ]]; then
  WATCH_DERIVED_DATA_FLAGS=(-derivedDataPath "$WATCH_DERIVED_DATA_PATH")
else
  unset WATCH_DERIVED_DATA_FLAGS
fi

run_watch_xcodebuild() {
  if [[ "${CI:-}" == "true" ]]; then
    python3 "$ROOT/tool/run_with_timeout.py" \
      --timeout "${CI_WATCH_XCODEBUILD_TIMEOUT_SECONDS:-1200}" \
      -- "$XCODEBUILD" "$@"
  else
    "$XCODEBUILD" "$@"
  fi
}

WATCH_ACTION="${CI_WATCH_XCODEBUILD_ACTION:-test}"
if [[ "$WATCH_DEST" == generic/* ]]; then
  # generic destinations cannot host XCTest; keep compile proof only.
  WATCH_ACTION=build
  echo "warning: no concrete watchOS Simulator UDID; running compile-only build" >&2
fi

# Unsigned compile is fine for build-only; hosted XCTest needs signing to install on Simulator.
WATCH_SIGN_FLAGS=()
if [[ "$WATCH_ACTION" == "build" ]] || [[ "${CI_WATCH_FORCE_UNSIGNED:-}" == "1" ]]; then
  WATCH_SIGN_FLAGS=(
    CODE_SIGNING_ALLOWED=NO
    CODE_SIGN_IDENTITY=-
  )
fi

watch_simulator_udid_from_dest() {
  sed -n 's/.*id=\([0-9A-Fa-f-]\{36\}\).*/\1/p' <<<"${1:-}" | tr '[:lower:]' '[:upper:]'
}

reset_watch_simulator_after_launch_flake() {
  local dest="$1"
  local udid
  udid="$(watch_simulator_udid_from_dest "$dest")"
  if [[ ! "$udid" =~ ^[0-9A-F-]{36}$ ]]; then
    return 0
  fi
  echo "warning: resetting watchOS Simulator $udid (shutdown + erase + boot)" >&2
  xcrun simctl shutdown "$udid" 2>/dev/null || true
  xcrun simctl erase "$udid" 2>/dev/null || true
  xcrun simctl boot "$udid" 2>/dev/null || true
  xcrun simctl bootstatus "$udid" -b 2>/dev/null || true
}

watch_log_indicates_launch_flake() {
  local log="$1"
  grep -Eq \
    'termination assertions|Failed to install or launch the test runner|FBSOpenApplicationServiceErrorDomain' \
    "$log"
}

run_watch_action() {
  run_watch_xcodebuild \
    -project superDemoApp.xcodeproj \
    -scheme superDemoAppWatch \
    -destination "$WATCH_DEST" \
    -configuration Debug \
    ${XCODEBUILD_SANDBOX_FLAGS+"${XCODEBUILD_SANDBOX_FLAGS[@]}"} \
    ${XCODEBUILD_WARNINGS_AS_ERRORS_FLAGS+"${XCODEBUILD_WARNINGS_AS_ERRORS_FLAGS[@]}"} \
    ${WATCH_DERIVED_DATA_FLAGS+"${WATCH_DERIVED_DATA_FLAGS[@]}"} \
    ${WATCH_SIGN_FLAGS+"${WATCH_SIGN_FLAGS[@]}"} \
    "$WATCH_ACTION"
}

echo "==> watchOS $WATCH_ACTION ($WATCH_DEST)"
watch_log="$(mktemp)"
trap 'rm -f "$watch_log"' EXIT

set +e
run_watch_action 2>&1 | tee "$watch_log"
watch_status=${PIPESTATUS[0]}
set -e

if ((watch_status != 0)); then
  if [[ "${CI:-}" == "true" ]] \
    && [[ "$WATCH_ACTION" == "test" ]] \
    && watch_log_indicates_launch_flake "$watch_log"
  then
    echo "warning: watchOS Simulator launch flake; retrying $WATCH_ACTION once" >&2
    reset_watch_simulator_after_launch_flake "$WATCH_DEST"
    run_watch_action || exit $?
  else
    exit "$watch_status"
  fi
fi

echo "watchOS $WATCH_ACTION passed."
