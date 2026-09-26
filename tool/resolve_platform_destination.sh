#!/usr/bin/env bash
# Resolve xcodebuild -destination strings for iPhone/iPad simulators and macOS.
# Source from other scripts: source "$(dirname "$0")/resolve_platform_destination.sh"
set -euo pipefail

_resolve_platform_root() {
  local script_dir
  if [[ -n "${BASH_VERSION:-}" && -n "${BASH_SOURCE[0]:-}" ]]; then
    script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  else
    script_dir="$(cd "$(dirname "$0")" && pwd)"
  fi
  cd "${script_dir}/.." && pwd
}
_resolve_platform_root_path="$(_resolve_platform_root)"
# shellcheck source=ios_simulator_runtime.sh
source "${_resolve_platform_root_path}/tool/ios_simulator_runtime.sh"
if [[ -z "${XCODEBUILD:-}" ]]; then
  # shellcheck source=xcode_env.sh
  source "${_resolve_platform_root_path}/tool/xcode_env.sh"
fi

iphone_udid_from_simctl() {
  local udid
  udid="$(find_iphone_udid_on_newest_runtime 2>/dev/null || true)"
  [[ -n "$udid" ]] || return 1
  printf '%s\n' "$udid"
}

destination_udid() {
  local dest="$1"
  sed -n 's/.*id=\([0-9A-F-]\{36\}\).*/\1/p' <<<"$dest"
}

xcodebuild_show_destinations() {
  if [[ -n "${DEVELOPER_DIR:-}" ]]; then
    refresh_xcodebuild_from_developer_dir
  fi
  "$XCODEBUILD" -showdestinations -project superDemoApp.xcodeproj -scheme superDemoApp 2>/dev/null
}

destination_valid_for_scheme() {
  local dest="$1"
  [[ -f superDemoApp.xcodeproj/project.pbxproj ]] || return 0
  local udid
  udid="$(destination_udid "$dest")"
  [[ "$udid" =~ ^[0-9A-F-]{36}$ ]] || return 1
  xcodebuild_show_destinations | grep -q "id:${udid}"
}

prefer_arm64_simulator_destination() {
  local dest="$1"
  # id= destinations already resolve to a concrete arm64 simulator; appending
  # arch=arm64 makes xcodebuild fail destination matching on CI.
  if [[ "$dest" == *"id="* || "$dest" == *"arch="* ]]; then
    printf '%s\n' "$dest"
    return
  fi
  printf '%s,arch=arm64\n' "$dest"
}

resolve_iphone_destination_from_xcodebuild() {
  [[ -f superDemoApp.xcodeproj/project.pbxproj ]] || return 1
  local dest_line
  dest_line="$(
    xcodebuild_show_destinations \
      | grep -E 'platform:iOS Simulator, id:[0-9A-F-]{36}' \
      | grep -v placeholder \
      | head -1 \
      || true
  )"
  [[ -n "$dest_line" ]] || return 1
  local udid
  udid="$(printf '%s\n' "$dest_line" | sed -n 's/.*id:\([0-9A-F-]\{36\}\).*/\1/p')"
  [[ "$udid" =~ ^[0-9A-F-]{36}$ ]] || return 1
  local dest="platform=iOS Simulator,id=${udid}"
  destination_valid_for_scheme "$dest" || return 1
  prefer_arm64_simulator_destination "$dest"
}

resolve_iphone_destination() {
  local dest
  if [[ -n "${CI_SIMULATOR_DEST:-}" ]]; then
    dest="${CI_SIMULATOR_DEST}"
    prefer_arm64_simulator_destination "$dest"
    return 0
  fi
  if [[ -n "${CHECKLIST_IPHONE_DEST:-}" ]]; then
    dest="${CHECKLIST_IPHONE_DEST}"
    prefer_arm64_simulator_destination "$dest"
    return 0
  fi

  local udid dest
  udid="$(find_iphone_udid_on_newest_runtime 2>/dev/null || true)"
  if [[ -n "$udid" ]]; then
    dest="platform=iOS Simulator,id=${udid}"
    if destination_valid_for_scheme "$dest"; then
      prefer_arm64_simulator_destination "$dest"
      return 0
    fi
  fi

  if dest="$(resolve_iphone_destination_from_xcodebuild)"; then
    prefer_arm64_simulator_destination "$dest"
    return 0
  fi

  if [[ "${CI:-}" == "true" ]]; then
    echo "error: no concrete iOS Simulator destination for CI (run ./tool/ensure_ci_simulator.sh)" >&2
    xcodebuild_show_destinations 2>&1 | head -40 >&2 || true
    return 1
  fi

  # Local fallback when simctl / xcodebuild cannot resolve a concrete UDID.
  # Prefer the newest marketing name; ensure_ci_simulator / simctl override on CI.
  printf 'platform=iOS Simulator,name=iPhone 18 Pro\n'
}

resolve_ipad_destination() {
  if [[ -n "${CI_IPAD_DEST:-}" ]]; then
    printf '%s\n' "$CI_IPAD_DEST"
    return 0
  fi
  if [[ -n "${CHECKLIST_IPAD_DEST:-}" ]]; then
    printf '%s\n' "$CHECKLIST_IPAD_DEST"
    return 0
  fi

  local udid dest
  udid="$(find_ipad_udid_on_newest_runtime 2>/dev/null || true)"
  if [[ -n "$udid" ]]; then
    dest="platform=iOS Simulator,id=${udid}"
    if destination_valid_for_scheme "$dest"; then
      prefer_arm64_simulator_destination "$dest"
      return 0
    fi
  fi

  if [[ "${CI:-}" == "true" ]]; then
    echo "error: no iPad simulator on newest iOS runtime for CI" >&2
    xcodebuild_show_destinations 2>&1 | head -40 >&2 || true
    return 1
  fi

  printf 'generic/platform=iOS Simulator\n'
}

resolve_mac_destination() {
  if [[ -n "${CI_MAC_DEST:-}" ]]; then
    printf '%s\n' "$CI_MAC_DEST"
    return 0
  fi
  if [[ -n "${CHECKLIST_MAC_DEST:-}" ]]; then
    printf '%s\n' "$CHECKLIST_MAC_DEST"
    return 0
  fi
  printf 'platform=macOS\n'
}
