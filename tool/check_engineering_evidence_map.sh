#!/usr/bin/env bash
# Check reviewer-facing evidence links and configured repository boundaries.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

MAP="docs/engineering/engineering-evidence-map.md"
errors=()

usage() {
  cat <<'HELP'
Usage: ./tool/check_engineering_evidence_map.sh [--help]

Checks evidence-map structure and source links, offline-invariant evidence,
README scope and badge honesty, and configured layer boundaries. Does not build
the app or run tests.
HELP
}

case "${1:-}" in
  -h|--help|help)
    usage
    exit 0
    ;;
  "")
    ;;
  *)
    echo "error: unknown option: $1" >&2
    usage >&2
    exit 2
    ;;
esac

require_file() {
  local path="$1"
  [[ -f "$path" ]] || errors+=("missing file: $path")
}

require_contains() {
  local path="$1"
  local needle="$2"
  if [[ ! -f "$path" ]]; then
    errors+=("missing file: $path")
  elif ! grep -qF -- "$needle" "$path"; then
    errors+=("$path missing required text: $needle")
  fi
}

forbid_regex() {
  local path="$1"
  local pattern="$2"
  local label="$3"
  if [[ -f "$path" ]] && grep -Eiq -- "$pattern" "$path"; then
    errors+=("$path still contains $label")
  fi
}

require_file "$MAP"
require_file "tool/check_engineering_evidence_map.sh"
require_file "tool/check_layer_boundaries.sh"
require_file "docs/engineering/validation_routing_fast_vs_full.md"
require_file "docs/offline-invariants.md"
require_file "docs/offline-first.md"
require_file "docs/layers.md"
require_file "docs/modularity.md"
require_file "docs/ci-cd-map.md"
require_file "docs/portfolio.md"
require_file "docs/sonar-decision.md"
require_file "README.md"
require_file ".github/workflows/ci.yml"
require_file "CODEMAP.md"
require_file "AGENTS.md"

for heading in "## Evidence areas" "## How to read results" "## Limits"; do
  require_contains "$MAP" "$heading"
done
require_contains "$MAP" "It does not build the app or run tests."
require_contains "$MAP" "It makes no aggregate engineering-quality rating."

areas=("Delivery" "Architecture" "Offline behavior" "Validation" "Portfolio scope")
for area in "${areas[@]}"; do
  if ! grep -qE "^\\|[[:space:]]*${area}[[:space:]]*\\|" "$MAP"; then
    errors+=("$MAP missing evidence row: $area")
  fi
done

require_contains "README.md" "Engineering-evidence"
require_contains "README.md" "docs/engineering/engineering-evidence-map.md"
require_contains "README.md" "This is a portfolio sample, not a shipped App Store product."
require_contains "CODEMAP.md" "docs/engineering/engineering-evidence-map.md"
require_contains "AGENTS.md" "engineering-evidence-map.md"
require_contains "docs/agents_quick_reference.md" "check_engineering_evidence_map.sh"
require_contains "bin/lint.sh" "check_engineering_evidence_map.sh"
require_contains "docs/portfolio.md" "engineering-evidence-map.md"
require_contains "docs/ci-cd-map.md" "Merge proof"
require_contains "docs/ci-cd-map.md" "iphone-test"
require_contains "docs/engineering/validation_routing_fast_vs_full.md" "## Fast Path"
require_contains "docs/engineering/validation_routing_fast_vs_full.md" "## Full Path"
require_contains "docs/sonar-decision.md" "Skip"

# Offline proof is a map of named invariants, not a synthetic quality score.
invariant_count="$(grep -cE '^\|[[:space:]]*\*\*OI-[0-9]+' docs/offline-invariants.md || true)"
if [[ "$invariant_count" -lt 5 ]]; then
  errors+=("offline-invariants.md has fewer than 5 named OI-* rows (found $invariant_count)")
fi
require_contains "docs/offline-invariants.md" "| Evidence |"
require_contains "docs/offline-first.md" "offline-invariants"

# Keep self-ratings and unmeasured coverage percentages off the cold path.
for path in README.md "$MAP"; do
  forbid_regex "$path" 'Engineering[^[:cntrl:]]*[0-9]+([[:space:]]*/[[:space:]]*10|%2F10)|Overall[^[:cntrl:]]*[0-9]+[[:space:]]*/[[:space:]]*10|10/10' "numeric engineering self-rating"
done
forbid_regex "README.md" 'coverage[^]]*([0-9]{1,3})%' "fake coverage % badge wording"
forbid_regex "README.md" 'Coverage-[0-9]+%25' "shields.io coverage percent badge"
forbid_regex "README.md" 'badge/coverage-' "coverage badge URL"

if ! ./tool/check_layer_boundaries.sh >/dev/null; then
  errors+=("configured layer-boundary check failed")
fi

if ((${#errors[@]} > 0)); then
  echo "error: Engineering evidence map gate failed:" >&2
  printf '  - %s\n' "${errors[@]}" >&2
  exit 1
fi

echo "Engineering evidence map gate passed."
