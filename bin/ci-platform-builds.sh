#!/usr/bin/env bash
# Universal platform compile proof: iPad simulator + macOS (used by ci.sh and CI workflow).
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

if [[ "${CI:-}" == "true" && -z "${CI_IPAD_DEST:-}" ]]; then
  CI_PREPARE_IPHONE="${CI_PREPARE_IPHONE:-0}" source "$ROOT/tool/ensure_ci_simulator.sh" || exit $?
fi

# shellcheck source=../tool/resolve_platform_destination.sh
source "$ROOT/tool/resolve_platform_destination.sh"
# shellcheck source=../tool/xcodebuild_sandbox_flags.sh
source "$ROOT/tool/xcodebuild_sandbox_flags.sh"

IPAD_DEST="$(resolve_ipad_destination)"
MAC_DEST="$(resolve_mac_destination)"
echo "==> iPad destination: $IPAD_DEST"
echo "==> Mac destination: $MAC_DEST"

run_platform_xcodebuild() {
  assert_xcodebuild_matches_developer_dir || return 1
  if [[ "${CI:-}" == "true" ]]; then
    python3 "$ROOT/tool/run_with_timeout.py" \
      --timeout "${CI_PLATFORM_XCODEBUILD_TIMEOUT_SECONDS:-1200}" \
      -- "$XCODEBUILD" "$@"
  else
    "$XCODEBUILD" "$@"
  fi
}

run_ipad_build() {
  echo "==> iPad build ($IPAD_DEST)"
  if [[ -n "${IPAD_DERIVED_DATA_PATH:-}" ]]; then
    IPAD_DERIVED_DATA_FLAGS=(-derivedDataPath "$IPAD_DERIVED_DATA_PATH")
  else
    unset IPAD_DERIVED_DATA_FLAGS
  fi

  run_platform_xcodebuild \
    -project superDemoApp.xcodeproj \
    -scheme superDemoApp \
    -destination "$IPAD_DEST" \
    -configuration Debug \
    ${XCODEBUILD_SANDBOX_FLAGS+"${XCODEBUILD_SANDBOX_FLAGS[@]}"} \
    ${IPAD_DERIVED_DATA_FLAGS+"${IPAD_DERIVED_DATA_FLAGS[@]}"} \
    build
}

run_mac_build() {
  echo "==> Mac build ($MAC_DEST)"
  if [[ -n "${MAC_DERIVED_DATA_PATH:-}" ]]; then
    MAC_DERIVED_DATA_FLAGS=(-derivedDataPath "$MAC_DERIVED_DATA_PATH")
  else
    unset MAC_DERIVED_DATA_FLAGS
  fi

  if [[ "${CI:-}" == "true" ]]; then
    # GitHub-hosted runners have no Mac Development certificate for the project team.
    MAC_BUILD_FLAGS=(
      CODE_SIGNING_ALLOWED=NO
      CODE_SIGN_IDENTITY=-
    )
  else
    unset MAC_BUILD_FLAGS
  fi

  run_platform_xcodebuild \
    -project superDemoApp.xcodeproj \
    -scheme superDemoApp \
    -destination "$MAC_DEST" \
    -configuration Debug \
    ${XCODEBUILD_SANDBOX_FLAGS+"${XCODEBUILD_SANDBOX_FLAGS[@]}"} \
    ${MAC_DERIVED_DATA_FLAGS+"${MAC_DERIVED_DATA_FLAGS[@]}"} \
    ${MAC_BUILD_FLAGS+"${MAC_BUILD_FLAGS[@]}"} \
    build
}

if [[ "${CI_SERIAL_PLATFORM_BUILDS:-0}" == "1" ]]; then
  run_ipad_build
  run_mac_build
else
  log_dir="$(mktemp -d)"
  trap 'rm -rf "$log_dir"' EXIT

  if [[ -z "${IPAD_DERIVED_DATA_PATH:-}" ]]; then
    export IPAD_DERIVED_DATA_PATH="$log_dir/DerivedData-iPad"
  fi
  if [[ -z "${MAC_DERIVED_DATA_PATH:-}" ]]; then
    export MAC_DERIVED_DATA_PATH="$log_dir/DerivedData-Mac"
  fi

  run_ipad_build >"$log_dir/ipad.log" 2>&1 &
  ipad_pid=$!
  run_mac_build >"$log_dir/mac.log" 2>&1 &
  mac_pid=$!

  ipad_status=0
  mac_status=0
  wait "$ipad_pid" || ipad_status=$?
  wait "$mac_pid" || mac_status=$?

  echo "==> iPad build log"
  cat "$log_dir/ipad.log"
  echo "==> Mac build log"
  cat "$log_dir/mac.log"

  if ((ipad_status != 0 || mac_status != 0)); then
    echo "error: platform builds failed (iPad=$ipad_status, Mac=$mac_status)" >&2
    exit 1
  fi
fi

echo "Platform builds passed."
