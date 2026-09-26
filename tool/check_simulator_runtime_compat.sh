#!/usr/bin/env bash
# Early gate: catch iOS Simulator runtime ↔ device-type mismatches before
# xcodebuild UI tests or manual Simulator runs.
#
# Catches the class of failure where simctl create returns 403 Incompatible
# device (e.g. global preferred iPhone 18 Pro on a 27.1 image that does not
# list that type under supportedDeviceTypes).
#
# Usage:
#   ./tool/check_simulator_runtime_compat.sh
#   ./tool/check_simulator_runtime_compat.sh --self-test   # fixture only (no simctl)
#
# Wired from: tool/check_common_issues.sh, bin/ci-iphone-test.sh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

failures=0
self_test=0

fail() {
  echo "error: $1" >&2
  failures=$((failures + 1))
}

warn() {
  echo "warning: $1" >&2
}

usage() {
  sed -n '2,14p' "$0" | sed 's/^# \{0,1\}//'
}

case "${1:-}" in
  -h|--help|help)
    usage
    exit 0
    ;;
  --self-test)
    self_test=1
    ;;
  "")
    ;;
  *)
    echo "error: unknown option: $1" >&2
    usage >&2
    exit 2
    ;;
esac

# --- Fixture self-test (algorithm; no host simctl required) -----------------
run_self_test() {
  echo "==> Simulator runtime compat self-test (fixtures)"
  python3 - <<'PY'
import json
import sys

preferred = (
    "iPhone 18 Pro",
    "iPhone 18 Pro Max",
    "iPhone 17 Pro",
    "iPhone 17",
)
exotic = ("Duo", "Fold", "Air")


def is_standard(name: str) -> bool:
    if not name or "iPhone" not in name:
        return False
    if any(m in name for m in exotic):
        return False
    return True


def pick(supported_names):
    by = {n: "id." + n.replace(" ", "-") for n in supported_names}
    for name in preferred:
        if name in by:
            return by[name]
    standard = [n for n in by if is_standard(n)]
    return by[standard[0]] if standard else None


# Case: 27.1 omits iPhone 18* (the GHA footgun). Prefer 17 Pro, not empty.
got = pick(["iPhone 17 Pro", "iPhone 17", "iPhone 16 Pro"])
if got != "id.iPhone-17-Pro":
    print(f"error: expected iPhone 17 Pro when 18 missing, got {got}", file=sys.stderr)
    sys.exit(1)

# Case: empty supported → None (caller must not create blind global preferred).
if pick([]) is not None:
    print("error: empty supported must yield no preferred type", file=sys.stderr)
    sys.exit(1)

# Case: 18 Pro present → pick it.
got = pick(["iPhone 18 Pro", "iPhone 17 Pro"])
if got != "id.iPhone-18-Pro":
    print(f"error: expected iPhone 18 Pro when listed, got {got}", file=sys.stderr)
    sys.exit(1)

print("ok: fixture selection prefers runtime-supported types")
PY
}

# Static regression: create path must walk runtime-supported types.
run_static_script_guards() {
  echo "==> Simulator provisioning script guards"
  local ensure="$ROOT/tool/ensure_ci_simulator.sh"
  local runtime="$ROOT/tool/ios_simulator_runtime.sh"

  [[ -f "$ensure" ]] || fail "missing $ensure"
  [[ -f "$runtime" ]] || fail "missing $runtime"

  if ! rg -q 'list_preferred_iphone_device_type_ids_for_runtime' "$ensure"; then
    fail "ensure_ci_simulator.sh must create via list_preferred_iphone_device_type_ids_for_runtime (runtime supportedDeviceTypes)"
  fi
  if ! rg -q 'select_preferred_iphone_device_type_id_for_runtime' "$runtime"; then
    fail "ios_simulator_runtime.sh must define select_preferred_iphone_device_type_id_for_runtime"
  fi
  if ! rg -q 'supportedDeviceTypes' "$runtime"; then
    fail "ios_simulator_runtime.sh must consult runtime supportedDeviceTypes"
  fi
}

# Live host checks (simctl + sourced helpers).
run_live_host_checks() {
  if ! command -v xcrun >/dev/null 2>&1; then
    warn "xcrun missing; skipping live simulator compat checks"
    return 0
  fi
  if ! xcrun simctl help >/dev/null 2>&1; then
    warn "simctl unavailable; skipping live simulator compat checks"
    return 0
  fi

  # shellcheck source=ios_simulator_runtime.sh
  source "$ROOT/tool/ios_simulator_runtime.sh"

  echo "==> Live simulator runtime ↔ device-type compat"

  local newest_id newest_ver global_id global_name
  newest_id="$(select_newest_ios_runtime_id || true)"
  if [[ -z "$newest_id" ]]; then
    fail "no available iOS Simulator runtime (install an iOS platform / runtime)"
    return 0
  fi
  newest_ver="$(ios_runtime_version "$newest_id")"
  echo "info: newest available runtime iOS ${newest_ver} (${newest_id})"

  global_id="$(select_preferred_iphone_device_type_id || true)"
  if [[ -z "$global_id" ]]; then
    fail "no global preferred standard iPhone device type found"
  else
    global_name="$(
      xcrun simctl list devicetypes -j 2>/dev/null \
        | python3 -c "
import json, sys
ident = sys.argv[1]
data = json.load(sys.stdin)
for t in data.get('devicetypes', []):
    if t.get('identifier') == ident:
        print(t.get('name', ''))
        break
" "$global_id" 2>/dev/null || true
    )"
    echo "info: global preferred device type ${global_name:-?} (${global_id})"
  fi

  local runtime_preferred existing
  runtime_preferred="$(select_preferred_iphone_device_type_id_for_runtime "$newest_id" || true)"
  existing="$(find_iphone_udid_on_runtime "$newest_id" || true)"

  local supported_count global_supported
  supported_count="$(
    xcrun simctl list runtimes -j 2>/dev/null \
      | python3 -c "
import json, sys
rid = sys.argv[1]
data = json.load(sys.stdin)
for r in data.get('runtimes', []):
    if r.get('identifier') == rid:
        print(len(r.get('supportedDeviceTypes') or []))
        sys.exit(0)
print(0)
" "$newest_id" 2>/dev/null || echo 0
  )"
  global_supported="$(
    xcrun simctl list runtimes -j 2>/dev/null \
      | python3 -c "
import json, sys
rid, want = sys.argv[1], sys.argv[2]
data = json.load(sys.stdin)
for r in data.get('runtimes', []):
    if r.get('identifier') != rid:
        continue
    for entry in r.get('supportedDeviceTypes') or []:
        if isinstance(entry, dict) and entry.get('identifier') == want:
            print('yes')
            sys.exit(0)
    print('no')
    sys.exit(0)
print('no')
" "$newest_id" "${global_id:-}" 2>/dev/null || echo no
  )"

  # The original footgun: blind create of global preferred on newest runtime.
  if [[ -n "$global_id" && "$supported_count" != "0" && "$global_supported" != "yes" ]]; then
    fail "global preferred ${global_name:-$global_id} is NOT in iOS ${newest_ver} supportedDeviceTypes — simctl create would 403 Incompatible device. Provision via list_preferred_iphone_device_type_ids_for_runtime (runtime prefers ${runtime_preferred:-none})"
  fi

  if [[ -z "$runtime_preferred" && "$supported_count" != "0" ]]; then
    fail "newest runtime iOS ${newest_ver} has supportedDeviceTypes but no standard preferred iPhone — update preferred list in ios_simulator_runtime.sh"
  fi

  if [[ "$supported_count" == "0" ]]; then
    # Dead/partial runtime (seen on some GHA images). Allow older-runtime
    # fallback only when another runtime can provision; still fail hard if none can.
    local any_usable=0
    local rid ver pref udid
    while IFS= read -r rid; do
      [[ -n "$rid" ]] || continue
      pref="$(select_preferred_iphone_device_type_id_for_runtime "$rid" || true)"
      udid="$(find_iphone_udid_on_runtime "$rid" || true)"
      if [[ -n "$pref" || -n "$udid" ]]; then
        any_usable=1
        ver="$(ios_runtime_version "$rid")"
        warn "newest runtime iOS ${newest_ver} has empty supportedDeviceTypes; will fall back to iOS ${ver} for provisioning (SDK mismatch risk)"
        break
      fi
    done < <(select_ios_runtime_ids_newest_first)
    if ((any_usable == 0)); then
      fail "no iOS Simulator runtime can provision a standard iPhone (empty supportedDeviceTypes / no devices)"
    fi
  fi

  if [[ -z "$runtime_preferred" && -z "$existing" && "$supported_count" != "0" ]]; then
    fail "newest runtime iOS ${newest_ver} has no creatable standard iPhone and no existing device"
  fi

  # SDK vs runtime honesty (warn locally; fail on CI when skew and newest unusable).
  local sdk
  sdk="$(ios_simulator_sdk_version || true)"
  if [[ -n "$sdk" && -n "$newest_ver" ]]; then
    local skew
    skew="$(
      python3 -c "
import sys

def vt(v):
    nums = [int(x) for x in v.split('.') if x.isdigit()]
    while len(nums) < 3:
        nums.append(0)
    return tuple(nums[:3])

sdk, runtime = sys.argv[1], sys.argv[2]
print('yes' if vt(sdk) > vt(runtime) else 'no')
" "$sdk" "$newest_ver"
    )"
    if [[ "$skew" == "yes" ]]; then
      msg="iphonesimulator SDK ${sdk} > newest runtime iOS ${newest_ver}"
      if [[ "${CI:-}" == "true" && -z "$existing" && -z "$runtime_preferred" ]]; then
        fail "${msg}; download/install matching simulator runtime before UI tests"
      else
        warn "${msg} (ensure_ci_simulator may download or fall back)"
      fi
    fi
  fi

  local rid ver types_n
  while IFS= read -r rid; do
    [[ -n "$rid" ]] || continue
    ver="$(ios_runtime_version "$rid")"
    types_n="$(
      xcrun simctl list runtimes -j 2>/dev/null \
        | python3 -c "
import json, sys
rid = sys.argv[1]
data = json.load(sys.stdin)
for r in data.get('runtimes', []):
    if r.get('identifier') == rid:
        print(len(r.get('supportedDeviceTypes') or []))
        sys.exit(0)
print(0)
" "$rid" 2>/dev/null || echo 0
    )"
    if [[ "$types_n" == "0" ]]; then
      warn "runtime iOS ${ver} (${rid}) has empty supportedDeviceTypes — create will skip it"
    fi
  done < <(select_ios_runtime_ids_newest_first | head -n 5)
}

run_self_test
run_static_script_guards

if ((self_test == 0)); then
  run_live_host_checks
else
  echo "info: --self-test only; skipped live simctl checks"
fi

if ((failures > 0)); then
  echo
  echo "Simulator runtime compat checks failed: ${failures}"
  echo "Fix device/runtime pairing before ./bin/ci-iphone-test.sh or manual Simulator runs."
  echo "See: docs/changes/2026-09-26_ci-sim-runtime-device-compat.md"
  exit 1
fi

echo "Simulator runtime compat checks passed."
