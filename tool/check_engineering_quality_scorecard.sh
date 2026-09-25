#!/usr/bin/env bash
# Honest gate for Engineering quality scorecard claims (no fake % badges).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

SCORECARD="docs/engineering/engineering-quality-scorecard.md"
missing=()

usage() {
  cat <<'EOF'
Usage: ./tool/check_engineering_quality_scorecard.sh [--help]

Validates Engineering scorecard wiring and honesty:
- scorecard structure + area rows
- overall = min(area scores)
- proof files / scripts for areas scored 10/10
- no fake coverage % badges on README
- offline invariants ≥5 named rows with evidence
Does not invent coverage numbers or run full ./bin/ci.sh (Xcode).
EOF
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
  [[ -f "$path" ]] || missing+=("missing file: $path")
}

require_contains() {
  local path="$1"
  local needle="$2"
  if [[ ! -f "$path" ]]; then
    missing+=("missing file: $path")
    return
  fi
  if ! grep -qF -- "$needle" "$path"; then
    missing+=("$path missing required text: $needle")
  fi
}

forbid_regex() {
  local path="$1"
  local pattern="$2"
  local label="$3"
  if [[ -f "$path" ]] && grep -Eiq -- "$pattern" "$path"; then
    missing+=("$path still contains $label")
  fi
}

area_score() {
  local area="$1"
  local line
  line="$(
    grep -E "^\\|[[:space:]]*${area}[[:space:]]*\\|[[:space:]]*[0-9]+[[:space:]]*/[[:space:]]*10[[:space:]]*\\|" \
      "$SCORECARD" \
      | head -n 1 || true
  )"
  if [[ -z "$line" ]]; then
    echo ""
    return
  fi
  echo "$line" | sed -E 's/^\|[[:space:]]*[^|]+[[:space:]]*\|[[:space:]]*([0-9]+)[[:space:]]*\/[[:space:]]*10[[:space:]]*\|.*/\1/'
}

overall_score() {
  local line
  line="$(
    grep -E '^\*\*Overall:[[:space:]]*[0-9]+/10\*\*' "$SCORECARD" | head -n 1 || true
  )"
  if [[ -z "$line" ]]; then
    echo ""
    return
  fi
  echo "$line" | sed -E 's/.*Overall:[[:space:]]*([0-9]+)\/10.*/\1/'
}

readme_engineering_badge_score() {
  if [[ ! -f README.md ]]; then
    echo ""
    return
  fi
  local line
  line="$(
    grep -Eo 'Engineering-[0-9]+%2F10|Engineering-[0-9]+/10' README.md | head -n 1 || true
  )"
  if [[ -z "$line" ]]; then
    echo ""
    return
  fi
  echo "$line" | sed -E 's/.*Engineering-([0-9]+).*/\1/'
}

echo "==> Engineering quality scorecard gate"

require_file "$SCORECARD"
require_file "tool/check_engineering_quality_scorecard.sh"
require_file "docs/engineering/validation_routing_fast_vs_full.md"
require_file "docs/offline-invariants.md"
require_file "docs/offline-first.md"
require_file "docs/layers.md"
require_file "docs/ci-cd-map.md"
require_file "docs/portfolio.md"
require_file "docs/sonar-decision.md"
require_file "bin/lint.sh"
require_file "bin/ci.sh"
require_file "bin/checklist-fast"
require_file "tool/check_layer_boundaries.sh"
require_file ".github/workflows/ci.yml"
require_file "CODEMAP.md"
require_file "AGENTS.md"
require_file "README.md"

require_contains "$SCORECARD" "## Scoring rule"
require_contains "$SCORECARD" "## Areas"
require_contains "$SCORECARD" "## Claim gate"
require_contains "$SCORECARD" "## Proof commands"
require_contains "$SCORECARD" "## Out of scope"
require_contains "$SCORECARD" "Overall = minimum"
require_contains "$SCORECARD" "./tool/check_engineering_quality_scorecard.sh"

require_contains "CODEMAP.md" "docs/engineering/engineering-quality-scorecard.md"
require_contains "AGENTS.md" "engineering-quality-scorecard"
require_contains "docs/agents_quick_reference.md" "check_engineering_quality_scorecard"
require_contains "bin/lint.sh" "check_engineering_quality_scorecard.sh"

# Area rows must exist.
areas=(
  "Delivery"
  "Architecture / layers"
  "Offline honesty"
  "Validation honesty"
  "Portfolio scope"
)

declare -a scores=()
for area in "${areas[@]}"; do
  score="$(area_score "$area")"
  if [[ -z "$score" ]]; then
    missing+=("$SCORECARD missing scored row for area: $area")
    continue
  fi
  if [[ "$score" != "0" && "$score" != "10" ]]; then
    missing+=("$SCORECARD area '$area' score must be 0/10 or 10/10 (got ${score}/10)")
  fi
  scores+=("$score")
done

claimed_overall="$(overall_score)"
if [[ -z "$claimed_overall" ]]; then
  missing+=("$SCORECARD missing **Overall: N/10** line")
else
  min_score=10
  for s in "${scores[@]:-}"; do
    if [[ -n "$s" && "$s" -lt "$min_score" ]]; then
      min_score="$s"
    fi
  done
  if [[ "$claimed_overall" -ne "$min_score" ]]; then
    missing+=("$SCORECARD Overall ${claimed_overall}/10 != min(areas) ${min_score}/10")
  fi
fi

# Honesty: no fake coverage % badges.
forbid_regex "README.md" 'coverage[^]]*([0-9]{1,3})%' "fake coverage % badge wording"
forbid_regex "README.md" 'Coverage-[0-9]+%25' "shields.io coverage percent badge"
forbid_regex "README.md" 'badge/coverage-' "coverage badge URL"

# Delivery (when 10): CI map honesty + scripts already required.
delivery="$(area_score "Delivery")"
if [[ "$delivery" == "10" ]]; then
  require_contains "docs/ci-cd-map.md" "Merge proof"
  require_contains "docs/ci-cd-map.md" "iphone-test"
  require_contains "README.md" "./bin/ci.sh"
fi

# Architecture (when 10): run layer boundary check.
architecture="$(area_score "Architecture / layers")"
if [[ "$architecture" == "10" ]]; then
  if ! ./tool/check_layer_boundaries.sh >/dev/null; then
    missing+=("Architecture / layers is 10/10 but check_layer_boundaries.sh failed")
  fi
fi

# Offline honesty (when 10): ≥5 named invariant rows with Evidence column cells.
offline="$(area_score "Offline honesty")"
if [[ "$offline" == "10" ]]; then
  invariant_count="$(
    grep -cE '^\|[[:space:]]*\*\*OI-[0-9]+' docs/offline-invariants.md || true
  )"
  if [[ "$invariant_count" -lt 5 ]]; then
    missing+=("Offline honesty is 10/10 but offline-invariants.md has fewer than 5 OI-* rows (found ${invariant_count})")
  fi
  require_contains "docs/offline-invariants.md" "| Evidence |"
  require_contains "docs/offline-first.md" "offline-invariants"
fi

# Validation honesty (when 10): fast vs full + PR/local honesty.
validation="$(area_score "Validation honesty")"
if [[ "$validation" == "10" ]]; then
  require_contains "docs/engineering/validation_routing_fast_vs_full.md" "## Fast Path"
  require_contains "docs/engineering/validation_routing_fast_vs_full.md" "## Full Path"
  require_contains "docs/ci-cd-map.md" "local"
  require_contains "docs/architecture-tour.md" "PR-lane vs local-test"
fi

# Portfolio scope (when 10): demo framing + Sonar skip; no App Store product claim.
portfolio="$(area_score "Portfolio scope")"
if [[ "$portfolio" == "10" ]]; then
  require_contains "README.md" "not a"
  require_contains "README.md" "shipped App Store product"
  require_contains "docs/sonar-decision.md" "Skip"
fi

# README Engineering badge only when overall is 10 and gate wiring is intact.
badge_score="$(readme_engineering_badge_score)"
if [[ -n "$badge_score" ]]; then
  if [[ "${claimed_overall:-0}" != "10" ]]; then
    missing+=("README has Engineering badge but Overall is not 10/10")
  fi
  if [[ "$badge_score" != "${claimed_overall:-}" ]]; then
    missing+=("README Engineering badge ${badge_score}/10 disagrees with Overall ${claimed_overall:-?}/10")
  fi
  require_contains "README.md" "docs/engineering/engineering-quality-scorecard.md"
fi

if ((${#missing[@]} > 0)); then
  echo "error: Engineering scorecard gate failed:" >&2
  printf '  - %s\n' "${missing[@]}" >&2
  exit 1
fi

echo "Engineering scorecard gate passed (Overall ${claimed_overall}/10)."
