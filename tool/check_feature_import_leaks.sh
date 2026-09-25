#!/usr/bin/env bash
# Fail on Feature A → Feature B type references (single-target modularity).
# Shared/ and App/ may compose features. See docs/modularity.md.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

DEFAULT_FEATURES_ROOT="superDemoApp/Features"
ALLOWLIST="$ROOT/tool/config/feature_import_leak_allowlist.txt"

failures=0
SCAN_ROOT=""
SELF_TEST=0

usage() {
  cat <<'EOF'
Usage: ./tool/check_feature_import_leaks.sh [--paths FEATURES_ROOT] [--self-test] [--help]

Default scope: superDemoApp/Features.
Builds a type index per feature (struct/class/enum/protocol/actor) and fails when
a feature Swift file references a type owned by another feature.
App/ and Shared/ are out of scope (composition is allowed there).
Allowlist: tool/config/feature_import_leak_allowlist.txt
  Format: FromFeature|ToFeature|TypeName|reason
EOF
}

fail() {
  echo "error: $1" >&2
  failures=$((failures + 1))
}

section() {
  printf '\n==> %s\n' "$1"
}

is_allowlisted() {
  local from="$1"
  local to="$2"
  local type_name="$3"
  local entry trimmed from_a to_a type_a
  [[ -f "$ALLOWLIST" ]] || return 1
  while IFS= read -r entry || [[ -n "$entry" ]]; do
    entry="${entry%%#*}"
    trimmed="${entry#"${entry%%[![:space:]]*}"}"
    trimmed="${trimmed%"${trimmed##*[![:space:]]}"}"
    [[ -n "$trimmed" ]] || continue
    IFS='|' read -r from_a to_a type_a _ <<<"$trimmed"
    [[ -n "${from_a:-}" && -n "${to_a:-}" && -n "${type_a:-}" ]] || continue
    if [[ "$from" == "$from_a" && "$to" == "$to_a" && "$type_name" == "$type_a" ]]; then
      return 0
    fi
  done <"$ALLOWLIST"
  return 1
}

run_leak_scan() {
  local features_root="$1"
  python3 - "$features_root" <<'PY'
import re
import sys
from pathlib import Path

features_root = Path(sys.argv[1])
if not features_root.is_dir():
    print(f"info: no {features_root}/; import leak checks skipped.", file=sys.stderr)
    sys.exit(0)

type_def = re.compile(
    r"(?m)^(?:@[^\n]+\n)*"
    r"(?:(?:public|internal|private|fileprivate|open|final|indirect|nonisolated)\s+)*"
    r"(?:struct|class|enum|protocol|actor)\s+(\w+)"
)

owned: dict[str, set[str]] = {}
feature_dirs = sorted(p for p in features_root.iterdir() if p.is_dir())
for feat in feature_dirs:
    names: set[str] = set()
    for path in feat.rglob("*.swift"):
        text = path.read_text(encoding="utf-8", errors="ignore")
        names.update(type_def.findall(text))
    owned[feat.name] = names

# Prefer unique owners; drop ambiguous names shared across features.
owner_of: dict[str, str] = {}
ambiguous: set[str] = set()
for feat, names in owned.items():
    for name in names:
        if name in ambiguous:
            continue
        if name in owner_of and owner_of[name] != feat:
            ambiguous.add(name)
            owner_of.pop(name, None)
            continue
        owner_of[name] = feat

leaks: list[tuple[str, str, str, str, int]] = []
for feat in feature_dirs:
    for path in feat.rglob("*.swift"):
        text = path.read_text(encoding="utf-8", errors="ignore")
        for name, other in owner_of.items():
            if other == feat.name:
                continue
            for match in re.finditer(rf"\b{re.escape(name)}\b", text):
                line = text.count("\n", 0, match.start()) + 1
                leaks.append((feat.name, other, name, str(path), line))

for from_f, to_f, name, path, line in leaks:
    # Machine-readable for the bash allowlist filter.
    print(f"{from_f}|{to_f}|{name}|{path}:{line}")
PY
}

run_self_test() {
  local fixture="$ROOT/tool/fixtures/feature_import_leaks"
  echo "==> Self-test against ${fixture#"$ROOT"/}"
  if [[ ! -d "$fixture/Features" ]]; then
    echo "error: missing fixture tree: ${fixture#"$ROOT"/}/Features" >&2
    exit 1
  fi
  local hits
  hits="$(run_leak_scan "$fixture/Features" || true)"
  if [[ -z "$hits" ]]; then
    echo "error: self-test expected cross-feature leak in fixture" >&2
    exit 1
  fi
  echo "$hits" | head -n 5
  echo "Self-test passed (fixture leaks detected as expected)."
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
      if [[ $# -eq 0 || "$1" == --* ]]; then
        echo "error: --paths requires a Features root directory" >&2
        exit 2
      fi
      SCAN_ROOT="$1"
      shift
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

if [[ -z "$SCAN_ROOT" ]]; then
  SCAN_ROOT="$DEFAULT_FEATURES_ROOT"
fi

section "Cross-feature import leaks (${SCAN_ROOT})"

if [[ ! -d "$SCAN_ROOT" ]]; then
  echo "info: no ${SCAN_ROOT}/; import leak checks skipped."
  exit 0
fi

while IFS= read -r row; do
  [[ -n "$row" ]] || continue
  IFS='|' read -r from_f to_f type_name loc <<<"$row"
  if is_allowlisted "$from_f" "$to_f" "$type_name"; then
    echo "info: allowlisted ${from_f} → ${to_f}.${type_name} (${loc})"
    continue
  fi
  fail "${from_f} must not reference ${to_f} type '${type_name}' (${loc})"
done < <(run_leak_scan "$SCAN_ROOT")

if ((failures > 0)); then
  echo
  echo "Cross-feature import leak checks failed: $failures"
  echo "Compose in App/ or Shared/; see docs/modularity.md"
  echo "Time-boxed exceptions: tool/config/feature_import_leak_allowlist.txt"
  exit 1
fi

echo "Cross-feature import leak checks passed."
