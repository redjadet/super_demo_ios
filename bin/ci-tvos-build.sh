#!/usr/bin/env bash
# tvOS Simulator: compile proof + Feed companion integration tests.
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

ci_has_tvos_simulator_destination() {
  "$XCODEBUILD" \
    -project superDemoApp.xcodeproj \
    -scheme superDemoAppTV \
    -showdestinations 2>&1 \
    | grep -q 'platform:tvOS Simulator'
}

if [[ "${CI:-}" == "true" ]] && ! ci_has_tvos_simulator_destination; then
  echo "warning: tvOS Simulator platform unavailable on this GitHub runner; skipping tvOS build/tests" >&2
  exit 0
fi

ensure_apple_tv_simulator() {
  local existing
  existing="$(xcrun simctl list devices available 2>/dev/null \
    | grep -E 'Apple TV' \
    | head -1 \
    | sed -n 's/.*(\([A-F0-9-]\{36\}\)).*/\1/p' || true)"
  if [[ -n "$existing" ]]; then
    printf '%s\n' "$existing"
    return 0
  fi
  # Create a durable sim when runtime is present but no device exists yet.
  xcrun simctl create "Apple TV 4K (3rd generation)" \
    "com.apple.CoreSimulator.SimDeviceType.Apple-TV-4K-3rd-generation-4K" \
    "com.apple.CoreSimulator.SimRuntime.tvOS-27-0" 2>/dev/null || true
  existing="$(xcrun simctl list devices available 2>/dev/null \
    | grep -E 'Apple TV' \
    | head -1 \
    | sed -n 's/.*(\([A-F0-9-]\{36\}\)).*/\1/p' || true)"
  printf '%s\n' "$existing"
}

resolve_tv_test_destination() {
  if [[ -n "${CI_TVOS_BUILD_DEST:-}" ]]; then
    printf '%s\n' "$CI_TVOS_BUILD_DEST"
    return 0
  fi
  local line id name
  line="$("$XCODEBUILD" -project superDemoApp.xcodeproj -scheme superDemoAppTV -showdestinations 2>/dev/null \
    | grep 'platform:tvOS Simulator' \
    | grep -v 'placeholder' \
    | grep 'id:' \
    | head -1 || true)"
  if [[ -n "$line" ]]; then
    id="$(sed -n 's/.*id:\([^,}]*\).*/\1/p' <<<"$line" | tr -d ' ')"
    name="$(sed -n 's/.*name:\([^}]*\).*/\1/p' <<<"$line" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
    if [[ -n "$id" && "$id" != *placeholder* ]]; then
      printf 'platform=tvOS Simulator,id=%s\n' "$id"
      return 0
    fi
    if [[ -n "$name" ]]; then
      printf 'platform=tvOS Simulator,name=%s\n' "$name"
      return 0
    fi
  fi
  id="$(ensure_apple_tv_simulator)"
  if [[ -n "$id" ]]; then
    printf 'platform=tvOS Simulator,id=%s\n' "$id"
    return 0
  fi
  printf '%s\n' "generic/platform=tvOS Simulator"
}

TV_DEST="$(resolve_tv_test_destination)"
echo "==> tvOS destination: $TV_DEST"

if [[ -n "${TVOS_DERIVED_DATA_PATH:-}" ]]; then
  TV_DERIVED_DATA_FLAGS=(-derivedDataPath "$TVOS_DERIVED_DATA_PATH")
else
  unset TV_DERIVED_DATA_FLAGS
fi

run_tv_xcodebuild() {
  if [[ "${CI:-}" == "true" ]]; then
    python3 "$ROOT/tool/run_with_timeout.py" \
      --timeout "${CI_TVOS_XCODEBUILD_TIMEOUT_SECONDS:-1200}" \
      -- "$XCODEBUILD" "$@"
  else
    "$XCODEBUILD" "$@"
  fi
}

TV_ACTION="${CI_TVOS_XCODEBUILD_ACTION:-test}"
if [[ "$TV_DEST" == generic/* ]]; then
  TV_ACTION=build
  echo "warning: no concrete tvOS Simulator UDID; running compile-only build" >&2
fi

TV_SIGN_FLAGS=()
if [[ "$TV_ACTION" == "build" ]] || [[ "${CI_TVOS_FORCE_UNSIGNED:-}" == "1" ]]; then
  TV_SIGN_FLAGS=(
    CODE_SIGNING_ALLOWED=NO
    CODE_SIGN_IDENTITY=-
  )
fi

tv_simulator_udid_from_dest() {
  sed -n 's/.*id=\([0-9A-Fa-f-]\{36\}\).*/\1/p' <<<"${1:-}" | tr '[:lower:]' '[:upper:]'
}

reset_tv_simulator_after_launch_flake() {
  local dest="$1"
  local udid
  udid="$(tv_simulator_udid_from_dest "$dest")"
  if [[ ! "$udid" =~ ^[0-9A-F-]{36}$ ]]; then
    return 0
  fi
  echo "warning: resetting tvOS Simulator $udid (shutdown + erase + boot)" >&2
  xcrun simctl shutdown "$udid" 2>/dev/null || true
  xcrun simctl erase "$udid" 2>/dev/null || true
  xcrun simctl boot "$udid" 2>/dev/null || true
  xcrun simctl bootstatus "$udid" -b 2>/dev/null || true
}

tv_log_indicates_launch_flake() {
  local log="$1"
  grep -Eq \
    'termination assertions|Failed to install or launch the test runner|FBSOpenApplicationServiceErrorDomain' \
    "$log"
}

run_tv_action() {
  run_tv_xcodebuild \
    -project superDemoApp.xcodeproj \
    -scheme superDemoAppTV \
    -destination "$TV_DEST" \
    -configuration Debug \
    ${XCODEBUILD_SANDBOX_FLAGS+"${XCODEBUILD_SANDBOX_FLAGS[@]}"} \
    ${XCODEBUILD_WARNINGS_AS_ERRORS_FLAGS+"${XCODEBUILD_WARNINGS_AS_ERRORS_FLAGS[@]}"} \
    ${TV_DERIVED_DATA_FLAGS+"${TV_DERIVED_DATA_FLAGS[@]}"} \
    ${TV_SIGN_FLAGS+"${TV_SIGN_FLAGS[@]}"} \
    "$TV_ACTION"
}

echo "==> tvOS $TV_ACTION ($TV_DEST)"
tv_log="$(mktemp)"
trap 'rm -f "$tv_log"' EXIT

set +e
run_tv_action 2>&1 | tee "$tv_log"
tv_status=${PIPESTATUS[0]}
set -e

if ((tv_status != 0)); then
  if [[ "${CI:-}" == "true" ]] \
    && [[ "$TV_ACTION" == "test" ]] \
    && tv_log_indicates_launch_flake "$tv_log"
  then
    echo "warning: tvOS Simulator launch flake; retrying $TV_ACTION once" >&2
    reset_tv_simulator_after_launch_flake "$TV_DEST"
    run_tv_action || exit $?
  else
    exit "$tv_status"
  fi
fi

echo "tvOS $TV_ACTION passed."
