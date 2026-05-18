#!/usr/bin/env bash
# Cursor afterFileEdit / afterTabFileEdit — SwiftFormat one edited file under superDemoApp.
# Fail open: missing tools or non-Swift paths exit 0.
set -euo pipefail

export PATH="/opt/homebrew/bin:/usr/local/bin:${PATH}"

input="$(cat)"
file_path=""

if command -v jq >/dev/null 2>&1; then
  file_path="$(printf '%s' "$input" | jq -r '.file_path // empty' 2>/dev/null || true)"
else
  file_path="$(printf '%s' "$input" | sed -n 's/.*"file_path"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -1)"
fi

if [[ -z "$file_path" ]] || [[ ! "$file_path" =~ \.swift$ ]]; then
  exit 0
fi

script_dir="$(cd "$(dirname "$0")" && pwd)"
app_root=""
search_dir="$script_dir"
while [[ "$search_dir" != "/" ]]; do
  if [[ -f "$search_dir/.swiftformat" && -f "$search_dir/bin/verify-swift.sh" ]]; then
    app_root="$search_dir"
    break
  fi
  search_dir="$(dirname "$search_dir")"
done

if [[ -z "$app_root" ]]; then
  exit 0
fi

case "$file_path" in
  "$app_root"/*) ;;
  *) exit 0 ;;
esac

if ! command -v swiftformat >/dev/null 2>&1; then
  exit 0
fi

swiftformat --config "$app_root/.swiftformat" "$file_path" >/dev/null 2>&1 || exit 0
exit 0
