#!/usr/bin/env bash
# Create and boot an iPhone simulator on CI on the newest iOS runtime (matches SDK).
set -euo pipefail

if [[ "${CI:-}" != "true" ]]; then
  exit 0
fi

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

# shellcheck source=resolve_platform_destination.sh
source "$ROOT/tool/resolve_platform_destination.sh"
# shellcheck source=ios_simulator_runtime.sh
source "$ROOT/tool/ios_simulator_runtime.sh"

finalize_ci_simulator_dest() {
  prefer_arm64_simulator_destination "$1"
}

if [[ -n "${CI_SIMULATOR_DEST:-}" ]]; then
  if destination_valid_for_scheme "${CI_SIMULATOR_DEST}"; then
    echo "==> CI simulator already configured (${CI_SIMULATOR_DEST})"
    exit 0
  fi
  echo "warning: CI_SIMULATOR_DEST invalid for scheme; reprovisioning" >&2
fi

boot_simulator_with_timeout() {
  local udid="$1"
  local timeout_seconds="${2:-120}"
  xcrun simctl boot "$udid" 2>/dev/null || true
  if command -v timeout >/dev/null 2>&1; then
    timeout "$timeout_seconds" xcrun simctl bootstatus "$udid" -b
  else
    xcrun simctl bootstatus "$udid" -b
  fi
}

wait_for_scheme_destination() {
  local dest="$1"
  local attempt
  for attempt in $(seq 1 24); do
    if destination_valid_for_scheme "$dest"; then
      return 0
    fi
    echo "==> Waiting for xcodebuild destination (attempt ${attempt}/24)..." >&2
    sleep 5
  done
  return 1
}

export_ci_simulator_dest() {
  local dest="$1"
  dest="$(finalize_ci_simulator_dest "$dest")"
  export CI_SIMULATOR_DEST="$dest"
  if [[ -n "${GITHUB_ENV:-}" ]]; then
    echo "CI_SIMULATOR_DEST=${dest}" >>"${GITHUB_ENV}"
  fi
  echo "==> CI simulator ready ($dest)"
}

try_newest_runtime_destination() {
  local udid dest runtime_version
  ensure_ios_runtime_matches_sdk
  runtime_id="$(select_newest_ios_runtime_id)" || return 1
  runtime_version="$(ios_runtime_version "$runtime_id")"
  echo "==> Using newest iOS Simulator runtime ${runtime_version} (${runtime_id})"

  udid="$(find_iphone_udid_on_runtime "$runtime_id" || true)"
  if [[ -z "$udid" ]]; then
    return 1
  fi

  boot_simulator_with_timeout "$udid" 120 || true

  dest="platform=iOS Simulator,id=${udid}"
  wait_for_scheme_destination "$dest" || return 1
  export_ci_simulator_dest "$dest"
  return 0
}

create_newest_runtime_simulator() {
  local runtime_id runtime_version device_type_id udid dest

  ensure_ios_runtime_matches_sdk
  runtime_id="$(select_newest_ios_runtime_id)" || true
  if [[ -z "$runtime_id" ]]; then
    echo "==> No iOS simulator runtime; downloading iOS platform"
    xcodebuild -downloadPlatform iOS
    runtime_id="$(select_newest_ios_runtime_id)" || true
  fi

  if [[ -z "$runtime_id" ]]; then
    echo "error: no iOS simulator runtime available" >&2
    xcrun simctl list runtimes >&2 || true
    exit 1
  fi

  runtime_version="$(ios_runtime_version "$runtime_id")"
  sdk_version="$(ios_simulator_sdk_version)"
  echo "==> Creating CI iPhone on iOS ${runtime_version} (SDK ${sdk_version:-unknown})"

  device_type_id="$(select_preferred_iphone_device_type_id)" || true
  if [[ -z "$device_type_id" ]]; then
    echo "error: no iPhone device type found" >&2
    exit 1
  fi

  udid="$(xcrun simctl create "CI iPhone" "$device_type_id" "$runtime_id")"
  echo "==> Created simulator ${udid}"

  boot_simulator_with_timeout "$udid" 180

  dest="platform=iOS Simulator,id=${udid}"
  if ! wait_for_scheme_destination "$dest"; then
    echo "error: xcodebuild does not accept destination after boot: $dest" >&2
    xcodebuild -showdestinations -project superDemoApp.xcodeproj -scheme superDemoApp 2>&1 | head -30 >&2 || true
    xcrun simctl list devices available >&2 || true
    exit 1
  fi

  export_ci_simulator_dest "$dest"
}

if try_newest_runtime_destination; then
  exit 0
fi

create_newest_runtime_simulator
