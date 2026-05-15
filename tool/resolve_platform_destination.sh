#!/usr/bin/env bash
# Resolve xcodebuild -destination strings for iPhone/iPad simulators and macOS.
# Source from other scripts: source "$(dirname "$0")/resolve_platform_destination.sh"
set -euo pipefail

resolve_iphone_destination_from_xcodebuild() {
  [[ -f superDemoApp.xcodeproj/project.pbxproj ]] || return 1
  local dest_line
  dest_line="$(
    xcodebuild -showdestinations -project superDemoApp.xcodeproj -scheme superDemoApp 2>/dev/null \
      | rg 'platform:iOS Simulator, id:[0-9A-F-]{36}' \
      | rg -v placeholder \
      | head -1 \
      || true
  )"
  [[ -n "$dest_line" ]] || return 1
  local udid
  udid="$(printf '%s\n' "$dest_line" | sed -n 's/.*id:\([0-9A-F-]\{36\}\).*/\1/p')"
  [[ "$udid" =~ ^[0-9A-F-]{36}$ ]] || return 1
  printf 'platform=iOS Simulator,id=%s\n' "$udid"
}

resolve_iphone_destination() {
  if [[ -n "${CI_SIMULATOR_DEST:-}" ]]; then
    printf '%s\n' "$CI_SIMULATOR_DEST"
    return 0
  fi
  if [[ -n "${CHECKLIST_IPHONE_DEST:-}" ]]; then
    printf '%s\n' "$CHECKLIST_IPHONE_DEST"
    return 0
  fi

  if [[ "${CI:-}" == "true" ]]; then
    resolve_iphone_destination_from_xcodebuild && return 0
  fi

  local preferred_name="${CHECKLIST_PREFERRED_IPHONE:-iPhone 17}"
  local devices
  devices="$(xcrun simctl list devices available 2>/dev/null || true)"

  local selected_line
  selected_line="$(printf '%s\n' "$devices" | awk '
    /^[[:space:]]+iPhone / && /\(Booted\)/ {
      print
      exit
    }
  ')"

  if [[ -z "$selected_line" ]]; then
    selected_line="$(printf '%s\n' "$devices" | awk -v preferred="$preferred_name" '
      /^[[:space:]]+iPhone / {
        line = $0
        sub(/^[[:space:]]+/, "", line)
        name = line
        sub(/[[:space:]]+\([0-9A-F-]{36}\).*/, "", name)
        if (name == preferred) {
          print
          exit
        }
      }
    ')"
  fi

  if [[ -z "$selected_line" ]]; then
    selected_line="$(printf '%s\n' "$devices" | awk '
      /^[[:space:]]+iPhone / {
        print
        exit
      }
    ')"
  fi

  if [[ -n "$selected_line" ]]; then
    local udid
    udid="$(printf '%s\n' "$selected_line" | sed -E 's/.*\(([0-9A-F-]{36})\).*/\1/')"
    if [[ "$udid" =~ ^[0-9A-F-]{36}$ ]]; then
      printf 'platform=iOS Simulator,id=%s\n' "$udid"
      return 0
    fi
  fi

  if [[ "${CI:-}" == "true" ]]; then
    resolve_iphone_destination_from_xcodebuild && return 0
    echo "error: no concrete iOS Simulator destination for CI tests" >&2
    xcodebuild -showdestinations -project superDemoApp.xcodeproj -scheme superDemoApp 2>&1 | head -40 >&2 || true
    return 1
  fi

  printf 'platform=iOS Simulator,name=%s\n' "$preferred_name"
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

  local preferred_name="${CHECKLIST_PREFERRED_IPAD:-iPad Pro 13-inch (M5)}"
  local devices
  devices="$(xcrun simctl list devices available 2>/dev/null || true)"

  local selected_line
  selected_line="$(printf '%s\n' "$devices" | awk -v preferred="$preferred_name" '
    /^[[:space:]]+iPad / {
      line = $0
      sub(/^[[:space:]]+/, "", line)
      name = line
      sub(/[[:space:]]+\([0-9A-F-]{36}\).*/, "", name)
      if (name == preferred) {
        print
        exit
      }
    }
  ')"

  if [[ -z "$selected_line" ]]; then
    selected_line="$(printf '%s\n' "$devices" | awk '
      /^[[:space:]]+iPad / {
        print
        exit
      }
    ')"
  fi

  if [[ -n "$selected_line" ]]; then
    local udid
    udid="$(printf '%s\n' "$selected_line" | sed -E 's/.*\(([0-9A-F-]{36})\).*/\1/')"
    if [[ "$udid" =~ ^[0-9A-F-]{36}$ ]]; then
      printf 'platform=iOS Simulator,id=%s\n' "$udid"
      return 0
    fi
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
