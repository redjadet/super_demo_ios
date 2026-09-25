#!/usr/bin/env bash
# Enforce layered feature folder skeleton under Features/<Name>/.
# See docs/modularity.md and docs/feature-template.md.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

LAYERED_LIST="$ROOT/tool/config/layered_features.txt"
NON_LAYERED_ALLOWLIST="$ROOT/tool/config/feature_folder_non_layered_allowlist.txt"
DEFAULT_FEATURES_ROOT="superDemoApp/Features"

failures=0
SCAN_ROOTS=()
FOCUSED=0
SELF_TEST=0

usage() {
  cat <<'EOF'
Usage: ./tool/check_feature_folder_contract.sh [--paths PATH...] [--self-test] [--help]

Default scope: superDemoApp/Features.
Rules for layered features:
  - Must have Presentation/, Domain/, and Data/ (each with ≥1 .swift)
  - No .swift files at the feature root
  - No banned alternate top-level layers (Application/, Infrastructure/, …)
A feature is layered when listed in tool/config/layered_features.txt, or when
it already has any of Presentation|Domain|Data (unless non-layered allowlisted).
EOF
}

fail() {
  echo "error: $1" >&2
  failures=$((failures + 1))
}

section() {
  printf '\n==> %s\n' "$1"
}

is_allowlisted_non_layered() {
  local name="$1"
  local entry trimmed
  [[ -f "$NON_LAYERED_ALLOWLIST" ]] || return 1
  while IFS= read -r entry || [[ -n "$entry" ]]; do
    entry="${entry%%#*}"
    trimmed="${entry#"${entry%%[![:space:]]*}"}"
    trimmed="${trimmed%"${trimmed##*[![:space:]]}"}"
    [[ -n "$trimmed" ]] || continue
    if [[ "$name" == "$trimmed" ]]; then
      return 0
    fi
  done <"$NON_LAYERED_ALLOWLIST"
  return 1
}

is_listed_layered() {
  local name="$1"
  local entry trimmed
  [[ -f "$LAYERED_LIST" ]] || return 1
  while IFS= read -r entry || [[ -n "$entry" ]]; do
    entry="${entry%%#*}"
    trimmed="${entry#"${entry%%[![:space:]]*}"}"
    trimmed="${trimmed%"${trimmed##*[![:space:]]}"}"
    [[ -n "$trimmed" ]] || continue
    if [[ "$name" == "$trimmed" ]]; then
      return 0
    fi
  done <"$LAYERED_LIST"
  return 1
}

has_any_layer_dir() {
  local feature_dir="$1"
  local layer
  for layer in Presentation Domain Data; do
    if [[ -d "${feature_dir}/${layer}" ]]; then
      return 0
    fi
  done
  return 1
}

is_layered_feature() {
  local feature_dir="$1"
  local name
  name="$(basename "$feature_dir")"
  if is_allowlisted_non_layered "$name"; then
    return 1
  fi
  if is_listed_layered "$name"; then
    return 0
  fi
  if has_any_layer_dir "$feature_dir"; then
    return 0
  fi
  return 1
}

layer_has_swift() {
  local dir="$1"
  [[ -d "$dir" ]] || return 1
  find "$dir" -type f -name '*.swift' -print -quit 2>/dev/null | grep -q .
}

check_feature_dir() {
  local feature_dir="$1"
  local name
  local layer
  local banned
  name="$(basename "$feature_dir")"

  if find "$feature_dir" -maxdepth 1 -type f -name '*.swift' -print -quit 2>/dev/null | grep -q .; then
    fail "Features/${name}/ has Swift at feature root; use Presentation/, Domain/, or Data/"
  fi

  for banned in Application Infrastructure ViewModels ViewModel Providers Models Services; do
    if [[ -d "${feature_dir}/${banned}" ]]; then
      fail "Features/${name}/ has banned top-level layer '${banned}/' (use Presentation/Domain/Data)"
    fi
  done

  if ! is_layered_feature "$feature_dir"; then
    if find "$feature_dir" -type f -name '*.swift' -print -quit 2>/dev/null | grep -q .; then
      echo "info: Features/${name}/ has Swift but is not marked layered (see tool/config/layered_features.txt)" >&2
    fi
    return 0
  fi

  for layer in Presentation Domain Data; do
    if [[ ! -d "${feature_dir}/${layer}" ]]; then
      fail "layered Features/${name}/ missing required ${layer}/"
      continue
    fi
    if ! layer_has_swift "${feature_dir}/${layer}"; then
      fail "layered Features/${name}/${layer}/ has no Swift sources"
    fi
  done
}

run_self_test() {
  local fixture="$ROOT/tool/fixtures/feature_folder_contract"
  local before
  echo "==> Self-test against ${fixture#"$ROOT"/}"
  if [[ ! -d "$fixture" ]]; then
    echo "error: missing fixture tree: ${fixture#"$ROOT"/}" >&2
    exit 1
  fi
  before=$failures
  check_feature_dir "$fixture/BadFeature"
  if ((failures <= before)); then
    echo "error: self-test expected folder-contract failures in BadFeature fixture" >&2
    exit 1
  fi
  echo "Self-test passed (fixture violations detected as expected)."
  exit 0
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help|help)
      usage
      exit 0
      ;;
    --paths)
      shift
      FOCUSED=1
      while [[ $# -gt 0 && "$1" != --* ]]; do
        SCAN_ROOTS+=("$1")
        shift
      done
      ;;
    --self-test)
      SELF_TEST=1
      shift
      ;;
    *)
      echo "error: unknown argument: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

if [[ "$SELF_TEST" -eq 1 ]]; then
  run_self_test
fi

if [[ "$FOCUSED" -eq 1 ]]; then
  if [[ "${#SCAN_ROOTS[@]}" -eq 0 ]]; then
    echo "error: --paths requires at least one path" >&2
    exit 2
  fi
else
  SCAN_ROOTS=("$DEFAULT_FEATURES_ROOT")
fi

section "Feature folder contract"

for scan_root in "${SCAN_ROOTS[@]}"; do
  if [[ -d "$scan_root" ]]; then
    # Feature root itself (when scanning Features/) or a single feature dir.
    if [[ "$(basename "$scan_root")" == "Features" ]] || [[ "$scan_root" == "$DEFAULT_FEATURES_ROOT" ]]; then
      shopt -s nullglob
      for feature_dir in "$scan_root"/*/; do
        [[ -d "$feature_dir" ]] || continue
        check_feature_dir "${feature_dir%/}"
      done
      shopt -u nullglob
    else
      check_feature_dir "$scan_root"
    fi
  elif [[ -f "$scan_root" ]]; then
    fail "expected a feature directory, got file: $scan_root"
  else
    echo "info: skip missing path ${scan_root}" >&2
  fi
done

if ((failures > 0)); then
  echo
  echo "Feature folder contract failed: $failures"
  echo "See docs/modularity.md and docs/feature-template.md"
  exit 1
fi

echo "Feature folder contract passed."
