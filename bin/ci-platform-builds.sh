#!/usr/bin/env bash
# Universal platform compile proof: iPad simulator + macOS (used by ci.sh and CI workflow).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

# shellcheck source=../tool/resolve_platform_destination.sh
source "$ROOT/tool/resolve_platform_destination.sh"

IPAD_DEST="$(resolve_ipad_destination)"
MAC_DEST="$(resolve_mac_destination)"

run_ipad_build() {
  echo "==> iPad build ($IPAD_DEST)"
  IPAD_DERIVED_DATA_FLAGS=()
  if [[ -n "${IPAD_DERIVED_DATA_PATH:-}" ]]; then
    IPAD_DERIVED_DATA_FLAGS=(-derivedDataPath "$IPAD_DERIVED_DATA_PATH")
  fi

  xcodebuild \
    -project superDemoApp.xcodeproj \
    -scheme superDemoApp \
    -destination "$IPAD_DEST" \
    -configuration Debug \
    "${IPAD_DERIVED_DATA_FLAGS[@]}" \
    build
}

run_mac_build() {
  echo "==> Mac build ($MAC_DEST)"
  MAC_DERIVED_DATA_FLAGS=()
  if [[ -n "${MAC_DERIVED_DATA_PATH:-}" ]]; then
    MAC_DERIVED_DATA_FLAGS=(-derivedDataPath "$MAC_DERIVED_DATA_PATH")
  fi

  MAC_BUILD_FLAGS=()
  if [[ "${CI:-}" == "true" ]]; then
    # GitHub-hosted runners have no Mac Development certificate for the project team.
    MAC_BUILD_FLAGS=(
      CODE_SIGNING_ALLOWED=NO
      CODE_SIGN_IDENTITY=-
    )
  fi

  xcodebuild \
    -project superDemoApp.xcodeproj \
    -scheme superDemoApp \
    -destination "$MAC_DEST" \
    -configuration Debug \
    "${MAC_DERIVED_DATA_FLAGS[@]}" \
    "${MAC_BUILD_FLAGS[@]}" \
    build
}

if [[ "${CI_SERIAL_PLATFORM_BUILDS:-0}" == "1" ]]; then
  run_ipad_build
  run_mac_build
else
  log_dir="$(mktemp -d)"
  trap 'rm -rf "$log_dir"' EXIT

  export IPAD_DERIVED_DATA_PATH="$log_dir/DerivedData-iPad"
  export MAC_DERIVED_DATA_PATH="$log_dir/DerivedData-Mac"

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
