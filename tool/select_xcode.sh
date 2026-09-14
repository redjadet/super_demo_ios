#!/usr/bin/env bash
# Pin active developer dir for CI + local parity.
# Prefer Xcode 27 locally (README). On GitHub macos-26 runners, prefer 26.6 then 26.5.
set -euo pipefail

if [[ -n "${SUPER_DEMO_XCODE_SELECTED:-}" ]]; then
  if [[ -n "${DEVELOPER_DIR:-}" && -x "${DEVELOPER_DIR}/usr/bin/xcodebuild" ]]; then
    return 0 2>/dev/null || exit 0
  fi
  unset SUPER_DEMO_XCODE_SELECTED
fi

# Ordered candidates. First existing app wins.
candidates=()
if [[ "${CI:-}" == "true" ]]; then
  candidates+=(
    /Applications/Xcode_26.6.app
    /Applications/Xcode_26.6.0.app
    /Applications/Xcode_26.5.app
    /Applications/Xcode_26.5.0.app
    /Applications/Xcode-26.5.0.app
  )
else
  candidates+=(
    /Applications/Xcode-27.0.0.app
    /Applications/Xcode_27.0.0.app
    /Applications/Xcode_27.0.app
    /Applications/Xcode_27.app
    /Applications/Xcode.app
    /Applications/Xcode_26.6.app
    /Applications/Xcode_26.6.0.app
    /Applications/Xcode_26.5.app
    /Applications/Xcode_26.5.0.app
  )
fi

xcode_app=""
for candidate in "${candidates[@]}"; do
  if [[ -d "$candidate" ]]; then
    xcode_app="$candidate"
    break
  fi
done

if [[ -z "$xcode_app" ]]; then
  echo "error: no supported Xcode app found. Checked:" >&2
  printf '  %s\n' "${candidates[@]}" >&2
  echo "Installed Xcode apps:" >&2
  find /Applications -maxdepth 1 -iname '*xcode*' -print 2>/dev/null >&2 || true
  exit 1
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
echo "Using ${xcode_app}"
echo "${version_line}"
echo "xcodebuild=$(command -v xcodebuild)"

# Accept Xcode 26.5+, 26.6.x, or 27.x (local README toolchain).
if [[ ! "$version_line" =~ Xcode\ (26\.[5-9]|26\.[1-9][0-9]|27\.) ]]; then
  echo "error: expected Xcode 26.5+ or 27.x, got: ${version_line}" >&2
  exit 1
fi

export SUPER_DEMO_XCODE_SELECTED=1
if [[ -n "${GITHUB_ENV:-}" ]]; then
  echo "SUPER_DEMO_XCODE_SELECTED=1" >>"$GITHUB_ENV"
fi
