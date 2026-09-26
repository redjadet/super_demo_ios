#!/usr/bin/env bash
# Select Xcode under /Applications (floor: 26.5; GHA Delivery sets SUPER_DEMO_XCODE_MIN_VERSION=27).
# CI: newest *released* first; beta/preview only if no released install qualifies.
# Local: newest install (released or seed) for README toolchain parity.
#
# Escape hatches:
#   SUPER_DEMO_XCODE_MIN_VERSION=26.5  — allow older hosts / macos-26 images
#   SUPER_DEMO_XCODE_SELECTED=1 + DEVELOPER_DIR — skip re-selection
set -euo pipefail

MIN_VERSION="${SUPER_DEMO_XCODE_MIN_VERSION:-26.5}"

if [[ -n "${SUPER_DEMO_XCODE_SELECTED:-}" ]]; then
  if [[ -n "${DEVELOPER_DIR:-}" && -x "${DEVELOPER_DIR}/usr/bin/xcodebuild" ]]; then
    return 0 2>/dev/null || exit 0
  fi
  unset SUPER_DEMO_XCODE_SELECTED
fi

version_meets_min() {
  local ver="$1"
  local lowest
  lowest="$(printf '%s\n%s\n' "$MIN_VERSION" "$ver" | sort -V | head -n1)"
  [[ "$lowest" == "$MIN_VERSION" ]]
}

xcode_build_number() {
  local app="$1"
  local build
  # Live xcodebuild is authoritative (Info.plist may omit the seed letter suffix).
  build="$("$app/Contents/Developer/usr/bin/xcodebuild" -version 2>/dev/null | sed -n '2p' | awk '{print $NF}')"
  if [[ -z "$build" ]]; then
    build="$(/usr/libexec/PlistBuddy -c 'Print :DTXcodeBuild' "$app/Contents/Info.plist" 2>/dev/null || true)"
  fi
  printf '%s' "$build" | tr -d '[:space:]'
}

is_beta_xcode() {
  local app="$1"
  local base info short build
  # Apple seed/beta ProductBuildVersion ends with a letter (e.g. 27A266a);
  # GM/release builds end in digits (e.g. 17F113, 27A9269). Trust the build
  # number over path labels — GHA may keep `_beta` in the app name after GM.
  build="$(xcode_build_number "$app")"
  if [[ -n "$build" ]]; then
    if [[ "$build" =~ [A-Za-z]$ ]]; then
      return 0
    fi
    return 1
  fi
  base="$(basename "$app")"
  if [[ "$base" == *[Bb]eta* || "$base" == *[Pp]review* ]]; then
    return 0
  fi
  info="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleGetInfoString' "$app/Contents/Info.plist" 2>/dev/null || true)"
  if [[ "$info" == *[Bb]eta* || "$info" == *[Pp]review* ]]; then
    return 0
  fi
  short="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$app/Contents/Info.plist" 2>/dev/null || true)"
  if [[ "$short" == *[Bb]eta* || "$short" == *[Pp]review* ]]; then
    return 0
  fi
  return 1
}

xcode_short_version() {
  local app="$1"
  /usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$app/Contents/Info.plist" 2>/dev/null \
    | sed -E 's/[^0-9.].*$//' \
    | tr -d '[:space:]'
}

resolve_app() {
  local app="$1"
  if command -v realpath >/dev/null 2>&1; then
    realpath "$app"
  else
    (cd "$app" && pwd -P)
  fi
}

# Ranked rows: channel(0=released,1=beta) \t version \t realpath
rank_file="$(mktemp)"
trap 'rm -f "$rank_file"' EXIT

shopt -s nullglob
apps=(/Applications/Xcode*.app /Applications/Xcode.app)
shopt -u nullglob

seen=$'\n'
for app in "${apps[@]}"; do
  [[ -d "$app" ]] || continue
  [[ -x "$app/Contents/Developer/usr/bin/xcodebuild" ]] || continue

  real="$(resolve_app "$app")"
  if [[ "$seen" == *$'\n'"$real"$'\n'* ]]; then
    continue
  fi
  seen="${seen}${real}"$'\n'

  ver="$(xcode_short_version "$real")"
  if [[ -z "$ver" ]] || ! version_meets_min "$ver"; then
    continue
  fi

  channel=0
  if is_beta_xcode "$real"; then
    channel=1
  fi
  printf '%s\t%s\t%s\n' "$channel" "$ver" "$real" >>"$rank_file"
done

if [[ ! -s "$rank_file" ]]; then
  echo "error: no Xcode >= ${MIN_VERSION} found under /Applications" >&2
  echo "Installed Xcode apps:" >&2
  find /Applications -maxdepth 1 -iname '*xcode*' -print 2>/dev/null >&2 || true
  exit 1
fi

if [[ "${CI:-}" == "true" ]]; then
  # CI: released first, then highest version.
  xcode_app="$(sort -t $'\t' -k1,1n -k2,2Vr "$rank_file" | head -n1 | cut -f3)"
else
  # Local: newest version (seed OK) so README Xcode 27 hosts keep working.
  xcode_app="$(sort -t $'\t' -k2,2Vr "$rank_file" | head -n1 | cut -f3)"
fi

developer_dir="${xcode_app}/Contents/Developer"
developer_bin="${developer_dir}/usr/bin"
export DEVELOPER_DIR="$developer_dir"
export PATH="${developer_bin}:${PATH}"
current_dir="$(xcode-select -p 2>/dev/null || true)"
if [[ "$current_dir" != "$developer_dir" ]]; then
  if [[ "${CI:-}" == "true" ]]; then
    sudo xcode-select -s "$developer_dir"
  elif ! xcode-select -s "$developer_dir" 2>/dev/null; then
    echo "warning: run: sudo xcode-select -s ${developer_dir}" >&2
  fi
fi

if [[ -n "${GITHUB_ENV:-}" ]]; then
  echo "DEVELOPER_DIR=${developer_dir}" >>"$GITHUB_ENV"
fi
if [[ -n "${GITHUB_PATH:-}" ]]; then
  echo "${developer_bin}" >>"$GITHUB_PATH"
fi

xcodebuild="${developer_bin}/xcodebuild"
version_line="$("$xcodebuild" -version 2>/dev/null | sed -n '1p')"
channel_label="released"
if is_beta_xcode "$xcode_app"; then
  if [[ "${CI:-}" == "true" ]]; then
    channel_label="beta/preview (no newer released install)"
  else
    channel_label="local newest (seed/beta allowed)"
  fi
fi
echo "Using ${xcode_app} [${channel_label}]"
echo "${version_line}"
echo "xcodebuild=$(command -v xcodebuild)"

picked_ver="$(echo "$version_line" | sed -E 's/^Xcode[[:space:]]+//' | sed -E 's/[^0-9.].*$//' | tr -d '[:space:]')"
if [[ -z "$picked_ver" ]] || ! version_meets_min "$picked_ver"; then
  echo "error: expected Xcode >= ${MIN_VERSION}, got: ${version_line}" >&2
  exit 1
fi

export SUPER_DEMO_XCODE_SELECTED=1
if [[ -n "${GITHUB_ENV:-}" ]]; then
  echo "SUPER_DEMO_XCODE_SELECTED=1" >>"$GITHUB_ENV"
fi
