#!/usr/bin/env bash
# Enforce Clean Architecture import and folder rules under Features/<Name>/.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

failures=0
features_root="superDemoApp/Features"

fail() {
  echo "error: $1" >&2
  failures=$((failures + 1))
}

section() {
  printf '\n==> %s\n' "$1"
}

check_forbidden_imports() {
  local file="$1"
  shift
  local label="$1"
  shift
  local pattern
  local line

  for pattern in "$@"; do
    line="$(rg -n "^[[:space:]]*import[[:space:]]+${pattern}\\b" "$file" || true)"
    if [[ -n "$line" ]]; then
      echo "$line" >&2
      fail "${label}: forbidden import ${pattern} in ${file#"$ROOT"/}"
    fi
  done
}

section "Layer import boundaries (Features/* only)"

if [[ ! -d "$features_root" ]]; then
  echo "info: no ${features_root}/ yet; layer import checks skipped."
else
  while IFS= read -r -d '' file; do
    check_forbidden_imports "$file" "Domain" \
      SwiftUI SwiftData UIKit AppKit URLSession Combine
  done < <(find "$features_root" -path '*/Domain/*.swift' -print0 2>/dev/null || true)

  while IFS= read -r -d '' file; do
    check_forbidden_imports "$file" "Presentation" SwiftData URLSession
  done < <(find "$features_root" -path '*/Presentation/*.swift' -print0 2>/dev/null || true)

  while IFS= read -r -d '' file; do
    check_forbidden_imports "$file" "Data" SwiftUI UIKit AppKit
  done < <(find "$features_root" -path '*/Data/*.swift' -print0 2>/dev/null || true)
fi

section "Feature folder layout"

if [[ -d "$features_root" ]]; then
  shopt -s nullglob
  for feature_dir in "$features_root"/*/; do
    [[ -d "$feature_dir" ]] || continue
    feature_name="$(basename "$feature_dir")"

    if find "$feature_dir" -maxdepth 1 -name '*.swift' -print -quit | grep -q .; then
      fail "Features/${feature_name}/ has Swift files at feature root; use Presentation/, Domain/, or Data/"
    fi

    has_layer_dir=0
    for layer in Presentation Domain Data; do
      if [[ -d "${feature_dir}${layer}" ]]; then
        has_layer_dir=1
      fi
    done

    if [[ "$has_layer_dir" -eq 0 ]] && find "$feature_dir" -name '*.swift' -print -quit | grep -q .; then
      fail "Features/${feature_name}/ has Swift files but no Presentation/, Domain/, or Data/ folder"
    fi

    for layer in Presentation Domain Data; do
      if [[ -d "${feature_dir}${layer}" ]] && ! find "${feature_dir}${layer}" -name '*.swift' -print -quit | grep -q .; then
        echo "warning: Features/${feature_name}/${layer}/ exists but has no Swift sources yet" >&2
      fi
    done
  done
  shopt -u nullglob
fi

if ((failures > 0)); then
  echo
  echo "Layer boundary checks failed: $failures"
  echo "See docs/architecture.md and docs/layers.md"
  exit 1
fi

echo "Layer boundary checks passed."
