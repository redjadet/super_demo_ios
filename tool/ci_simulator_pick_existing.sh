#!/usr/bin/env bash
# Pick an already-installed iPhone Simulator destination for CI.
# Never creates or erases devices. Source or execute; exports CI_SIMULATOR_DEST.
#
# Usage:
#   source ./tool/ci_simulator_pick_existing.sh
#   ./tool/ci_simulator_pick_existing.sh   # prints destination; sets GITHUB_ENV when present
set -euo pipefail

_pick_is_sourced() {
  [[ "${BASH_SOURCE[0]}" != "${0}" ]]
}

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

if [[ "${CI:-}" == "true" ]]; then
  # shellcheck source=select_xcode.sh
  source "$ROOT/tool/select_xcode.sh"
fi

# shellcheck source=xcode_env.sh
source "$ROOT/tool/xcode_env.sh"
# shellcheck source=ios_simulator_runtime.sh
source "$ROOT/tool/ios_simulator_runtime.sh"
# shellcheck source=resolve_platform_destination.sh
source "$ROOT/tool/resolve_platform_destination.sh"

if [[ -n "${CI_SIMULATOR_DEST:-}" ]]; then
  udid="$(destination_udid "${CI_SIMULATOR_DEST}")"
  if [[ "$udid" =~ ^[0-9A-F-]{36}$ ]]; then
    echo "==> Reusing CI_SIMULATOR_DEST=${CI_SIMULATOR_DEST}"
    if _pick_is_sourced; then
      return 0
    fi
    printf '%s\n' "$CI_SIMULATOR_DEST"
    exit 0
  fi
fi

udid="$(find_iphone_udid_on_newest_runtime || true)"
if [[ -z "$udid" || ! "$udid" =~ ^[0-9A-Fa-f-]{36}$ ]]; then
  echo "error: no installed iPhone simulator found (CI_SIMULATOR_REUSE_ONLY; will not create)" >&2
  xcrun simctl list devices available 2>&1 | head -40 >&2 || true
  if _pick_is_sourced; then
    return 1
  fi
  exit 1
fi

udid="$(tr '[:lower:]' '[:upper:]' <<<"$udid")"
dest="platform=iOS Simulator,id=${udid}"
# Prefer id= form directly — skip name/OS round-trips.
export CI_SIMULATOR_DEST="$dest"
if [[ -n "${GITHUB_ENV:-}" ]]; then
  echo "CI_SIMULATOR_DEST=${dest}" >>"${GITHUB_ENV}"
fi
echo "==> Picked existing iPhone simulator ${dest}"

if _pick_is_sourced; then
  return 0
fi
printf '%s\n' "$dest"
