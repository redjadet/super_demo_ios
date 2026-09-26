#!/usr/bin/env bash
# Create and boot an iPhone simulator on CI on the newest iOS runtime (matches SDK).
# Source from CI scripts so exported CI_*_DEST vars stay in the parent shell.
set -euo pipefail

_ensure_is_sourced() {
  [[ "${BASH_SOURCE[0]}" != "${0}" ]]
}

_ensure_done() {
  local code="${1:-0}"
  if _ensure_is_sourced; then
    return "$code"
  fi
  exit "$code"
}

_ensure_fatal() {
  local code="${1:-1}"
  if _ensure_is_sourced; then
    return "$code"
  fi
  exit "$code"
}

if [[ "${CI:-}" != "true" ]]; then
  _ensure_done 0
fi

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

if [[ "${CI:-}" == "true" ]]; then
  # shellcheck source=select_xcode.sh
  source "$ROOT/tool/select_xcode.sh"
fi

# shellcheck source=xcode_env.sh
source "$ROOT/tool/xcode_env.sh"
echo "==> ensure_ci_simulator using ${XCODEBUILD}"
# shellcheck source=resolve_platform_destination.sh
source "$ROOT/tool/resolve_platform_destination.sh"
# shellcheck source=ios_simulator_runtime.sh
source "$ROOT/tool/ios_simulator_runtime.sh"

CI_PREPARE_IPHONE="${CI_PREPARE_IPHONE:-1}"
CI_PREPARE_IPAD="${CI_PREPARE_IPAD:-1}"

finalize_ci_simulator_dest() {
  prefer_arm64_simulator_destination "$1"
}

if [[ "$CI_PREPARE_IPHONE" != "1" && "$CI_PREPARE_IPAD" != "1" ]]; then
  echo "error: CI_PREPARE_IPHONE=0 and CI_PREPARE_IPAD=0; nothing to prepare" >&2
  _ensure_fatal 2
fi

iphone_ready=0
ipad_ready=0
if [[ "$CI_PREPARE_IPHONE" != "1" ]]; then
  iphone_ready=1
elif [[ -n "${CI_SIMULATOR_DEST:-}" ]] && destination_valid_for_scheme "${CI_SIMULATOR_DEST}"; then
  iphone_ready=1
fi
if [[ "$CI_PREPARE_IPAD" != "1" ]]; then
  ipad_ready=1
elif [[ -n "${CI_IPAD_DEST:-}" ]] && destination_valid_for_scheme "${CI_IPAD_DEST}"; then
  ipad_ready=1
fi
if ((iphone_ready == 1 && ipad_ready == 1)); then
  echo "==> CI simulators already configured"
  _ensure_done 0
fi
echo "warning: CI simulator destination missing or invalid; provisioning required devices" >&2

boot_simulator_with_timeout() {
  local udid="$1"
  local timeout_seconds="${2:-120}"
  xcrun simctl boot "$udid" 2>/dev/null || true
  if command -v timeout >/dev/null 2>&1; then
    timeout "$timeout_seconds" xcrun simctl bootstatus "$udid" -b
  elif [[ -f "$ROOT/tool/run_with_timeout.py" ]]; then
    python3 "$ROOT/tool/run_with_timeout.py" \
      --timeout "$timeout_seconds" \
      -- xcrun simctl bootstatus "$udid" -b
  else
    xcrun simctl bootstatus "$udid" -b
  fi
}

wait_for_scheme_destination() {
  local udid="$1"
  local dest attempt alt_dest
  dest="platform=iOS Simulator,id=${udid}"
  for attempt in $(seq 1 24); do
    if destination_valid_for_scheme "$dest"; then
      printf '%s\n' "$dest"
      return 0
    fi
    echo "==> Waiting for xcodebuild destination (attempt ${attempt}/24)..." >&2
    sleep 5
  done
  # name=OS= form sometimes appears before id= is recognized.
  alt_dest="$(scheme_destination_for_udid "$udid" || true)"
  if [[ -n "$alt_dest" ]] && destination_valid_for_scheme "$alt_dest"; then
    printf '%s\n' "$alt_dest"
    return 0
  fi
  echo "error: xcodebuild -showdestinations never listed simulator ${udid}" >&2
  xcodebuild_show_destinations 2>&1 | head -40 >&2 || true
  xcrun simctl list devices available 2>&1 | head -40 >&2 || true
  return 1
}

export_ci_simulator_dest() {
  local dest="$1"
  dest="$(finalize_ci_simulator_dest "$dest")"
  if ! destination_valid_for_scheme "$dest"; then
    echo "error: refusing to export CI_SIMULATOR_DEST that xcodebuild cannot see: ${dest}" >&2
    return 1
  fi
  export CI_SIMULATOR_DEST="$dest"
  if [[ -n "${GITHUB_ENV:-}" ]]; then
    echo "CI_SIMULATOR_DEST=${dest}" >>"${GITHUB_ENV}"
  fi
  echo "==> CI iPhone simulator ready ($dest)"
}

export_ci_ipad_dest() {
  local dest="$1"
  dest="$(finalize_ci_simulator_dest "$dest")"
  export CI_IPAD_DEST="$dest"
  if [[ -n "${GITHUB_ENV:-}" ]]; then
    echo "CI_IPAD_DEST=${dest}" >>"${GITHUB_ENV}"
  fi
  echo "==> CI iPad simulator ready ($dest)"
}

provision_ipad_on_runtime() {
  local runtime_id="$1"
  local udid device_type_id dest

  udid="$(find_ipad_udid_on_runtime "$runtime_id" || true)"
  if [[ -z "$udid" ]]; then
    device_type_id="$(select_preferred_ipad_device_type_id)" || return 1
    udid="$(xcrun simctl create "CI iPad" "$device_type_id" "$runtime_id")"
    echo "==> Created iPad simulator ${udid}"
  fi

  boot_simulator_with_timeout "$udid" 120 || true
  dest="$(wait_for_scheme_destination "$udid")" || return 1
  export_ci_ipad_dest "$dest"
}

try_newest_runtime_destination() {
  local udid dest runtime_id runtime_version
  ensure_ios_runtime_matches_sdk

  # Prefer a standard iPhone on the newest runtime xcodebuild can actually see.
  while IFS= read -r runtime_id; do
    [[ -n "$runtime_id" ]] || continue
    runtime_version="$(ios_runtime_version "$runtime_id")"
    udid="$(find_iphone_udid_on_runtime "$runtime_id" || true)"
    if [[ -z "$udid" ]]; then
      echo "==> No standard iPhone on iOS ${runtime_version}; trying older runtime or create" >&2
      continue
    fi
    echo "==> Trying iOS Simulator runtime ${runtime_version} (${runtime_id}) udid=${udid}"
    boot_simulator_with_timeout "$udid" 120 || true
    if dest="$(wait_for_scheme_destination "$udid")"; then
      export_ci_simulator_dest "$dest" || continue
      return 0
    fi
    echo "warning: runtime ${runtime_version} device not visible to xcodebuild; trying next" >&2
  done < <(select_ios_runtime_ids_newest_first)

  return 1
}

create_newest_runtime_simulator() {
  local runtime_id runtime_version device_type_id udid dest

  ensure_ios_runtime_matches_sdk
  device_type_id="$(select_preferred_iphone_device_type_id)" || true
  if [[ -z "$device_type_id" ]]; then
    echo "error: no standard iPhone device type found" >&2
    _ensure_fatal 1
  fi

  while IFS= read -r runtime_id; do
    [[ -n "$runtime_id" ]] || continue
    runtime_version="$(ios_runtime_version "$runtime_id")"
    sdk_version="$(ios_simulator_sdk_version)"
    echo "==> Creating CI iPhone (${device_type_id}) on iOS ${runtime_version} (SDK ${sdk_version:-unknown})"

    udid="$(xcrun simctl create "CI iPhone" "$device_type_id" "$runtime_id" 2>/dev/null || true)"
    if [[ -z "$udid" ]]; then
      echo "warning: could not create ${device_type_id} on ${runtime_version}; trying next runtime" >&2
      continue
    fi
    echo "==> Created simulator ${udid}"

    boot_simulator_with_timeout "$udid" 180 || true

    if dest="$(wait_for_scheme_destination "$udid")" \
      && export_ci_simulator_dest "$dest"; then
      return 0
    fi
    echo "warning: created simulator on ${runtime_version} not visible to xcodebuild; trying next" >&2
    xcrun simctl delete "$udid" 2>/dev/null || true
  done < <(select_ios_runtime_ids_newest_first)

  # Last resort: download platform if we still have no usable runtime pairing.
  echo "==> No usable iPhone destination; downloading iOS platform and retrying once"
  refresh_xcodebuild_from_developer_dir
  "$XCODEBUILD" -downloadPlatform iOS || true
  runtime_id="$(select_newest_ios_runtime_id)" || true
  if [[ -z "$runtime_id" ]]; then
    echo "error: no iOS simulator runtime available" >&2
    xcrun simctl list runtimes >&2 || true
    _ensure_fatal 1
  fi
  runtime_version="$(ios_runtime_version "$runtime_id")"
  udid="$(xcrun simctl create "CI iPhone" "$device_type_id" "$runtime_id")"
  echo "==> Created simulator ${udid} on iOS ${runtime_version}"
  boot_simulator_with_timeout "$udid" 180
  dest="$(wait_for_scheme_destination "$udid")" || {
    echo "error: xcodebuild does not accept destination after boot for ${udid}" >&2
    xcodebuild_show_destinations 2>&1 | head -30 >&2 || true
    xcrun simctl list devices available >&2 || true
    _ensure_fatal 1
  }
  export_ci_simulator_dest "$dest" || _ensure_fatal 1
}

if [[ "$CI_PREPARE_IPHONE" == "1" ]]; then
  if ! try_newest_runtime_destination; then
    create_newest_runtime_simulator
  fi
  # Prefer the runtime of the exported iPhone destination for iPad pairing.
  runtime_id=""
  if [[ -n "${CI_SIMULATOR_DEST:-}" ]]; then
    _iphone_udid="$(destination_udid "${CI_SIMULATOR_DEST}")"
    if [[ "${_iphone_udid}" =~ ^[0-9A-F-]{36}$ ]]; then
      runtime_id="$(
        xcrun simctl list devices -j 2>/dev/null \
          | python3 -c "
import json, sys
udid = sys.argv[1]
data = json.load(sys.stdin)
for rid, devices in data.get('devices', {}).items():
    for d in devices:
        if d.get('udid') == udid:
            print(rid)
            sys.exit(0)
sys.exit(1)
" "${_iphone_udid}" 2>/dev/null || true
      )"
    fi
    unset _iphone_udid
  fi
  if [[ -z "$runtime_id" ]]; then
    runtime_id="$(select_newest_ios_runtime_id)" || true
  fi
else
  ensure_ios_runtime_matches_sdk
  runtime_id="$(select_newest_ios_runtime_id)" || true
  if [[ -z "$runtime_id" ]]; then
    echo "error: no iOS simulator runtime available" >&2
    xcrun simctl list runtimes >&2 || true
    _ensure_fatal 1
  fi
fi

if [[ "$CI_PREPARE_IPAD" == "1" ]]; then
  provision_ipad_on_runtime "$runtime_id"
fi
