#!/usr/bin/env bash
# Pin active developer dir to Xcode 26.5.x (CI + local parity with README badge).
set -euo pipefail

readonly REQUIRED_MAJOR_MINOR="26.5"

candidates=(
  /Applications/Xcode_26.5.0.app
  /Applications/Xcode_26.5.app
  /Applications/Xcode-26.5.0.app
  /Applications/Xcode_26.5_beta_2.app
)

xcode_app=""
for candidate in "${candidates[@]}"; do
  if [[ -d "$candidate" ]]; then
    xcode_app="$candidate"
    break
  fi
done

if [[ -z "$xcode_app" ]]; then
  echo "error: Xcode ${REQUIRED_MAJOR_MINOR} not found. Checked:" >&2
  printf '  %s\n' "${candidates[@]}" >&2
  echo "Installed Xcode apps:" >&2
  ls -1 /Applications 2>/dev/null | grep -i xcode >&2 || true
  exit 1
fi

developer_dir="${xcode_app}/Contents/Developer"
current_dir="$(xcode-select -p 2>/dev/null || true)"
if [[ "$current_dir" != "$developer_dir" ]]; then
  if [[ "${CI:-}" == "true" ]]; then
    sudo xcode-select -s "$developer_dir"
  elif ! xcode-select -s "$developer_dir" 2>/dev/null; then
    echo "warning: run: sudo xcode-select -s ${developer_dir}" >&2
  fi
fi

version_line="$(xcodebuild -version 2>/dev/null | sed -n '1p')"
echo "Using ${xcode_app}"
echo "${version_line}"

if [[ "$version_line" != *"Xcode ${REQUIRED_MAJOR_MINOR}"* ]]; then
  echo "error: expected Xcode ${REQUIRED_MAJOR_MINOR}.x, got: ${version_line}" >&2
  exit 1
fi
