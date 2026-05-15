#!/usr/bin/env bash
# Create and boot an iPhone simulator on CI when none is available for xcodebuild.
set -euo pipefail

if [[ "${CI:-}" != "true" ]]; then
  exit 0
fi

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

# shellcheck source=resolve_platform_destination.sh
source "$ROOT/tool/resolve_platform_destination.sh"

read_deployment_target() {
  local project_file="superDemoApp.xcodeproj/project.pbxproj"
  [[ -f "$project_file" ]] || return 1
  rg -m1 'IPHONEOS_DEPLOYMENT_TARGET = ' "$project_file" \
    | sed -E 's/.*IPHONEOS_DEPLOYMENT_TARGET = ([0-9]+(\.[0-9]+)?);.*/\1/'
}

select_ios_runtime_id() {
  local deployment_target="$1"
  local mode="${2:-strict}"
  xcrun simctl list runtimes -j 2>/dev/null \
    | python3 -c "
import json, sys

target = sys.argv[1]
mode = sys.argv[2]
parts = [int(x) for x in target.split('.') if x.isdigit()]
while len(parts) < 2:
    parts.append(0)
target_tuple = tuple(parts[:2])

def version_tuple(runtime):
    nums = [int(x) for x in runtime.get('version', '0').split('.') if x.isdigit()]
    while len(nums) < 2:
        nums.append(0)
    return tuple(nums[:2])

data = json.load(sys.stdin)
ios = [
    r for r in data.get('runtimes', [])
    if r.get('isAvailable') and 'iOS' in r.get('name', '')
]
if not ios:
    sys.exit(1)
matching = [r for r in ios if version_tuple(r) >= target_tuple]
if not matching and mode == 'best':
    matching = ios
if not matching:
    sys.exit(1)
matching.sort(key=version_tuple, reverse=True)
print(matching[0]['identifier'])
" "$deployment_target" "$mode" 2>/dev/null || true
}

wait_for_scheme_destination() {
  local dest="$1"
  local attempt
  for attempt in $(seq 1 40); do
    if destination_valid_for_scheme "$dest"; then
      return 0
    fi
    sleep 5
  done
  return 1
}

try_existing_destination() {
  local udid
  udid="$(iphone_udid_from_simctl 2>/dev/null || true)"
  [[ -n "$udid" ]] || return 1
  local dest="platform=iOS Simulator,id=${udid}"
  wait_for_scheme_destination "$dest" || return 1
  echo "==> CI simulator already available ($dest)"
  export CI_SIMULATOR_DEST="$dest"
  if [[ -n "${GITHUB_ENV:-}" ]]; then
    echo "CI_SIMULATOR_DEST=${dest}" >>"${GITHUB_ENV}"
  fi
  return 0
}

if try_existing_destination; then
  exit 0
fi

deployment_target="$(read_deployment_target || echo "26.0")"
echo "==> Preparing iOS Simulator for deployment target ${deployment_target}"

runtime_id="$(select_ios_runtime_id "$deployment_target" strict)"
if [[ -z "$runtime_id" ]]; then
  echo "==> No iOS ${deployment_target}+ runtime; downloading iOS platform"
  xcodebuild -downloadPlatform iOS
  runtime_id="$(select_ios_runtime_id "$deployment_target" strict)"
fi

if [[ -z "$runtime_id" ]]; then
  echo "warning: no runtime >= ${deployment_target}; using newest available iOS runtime" >&2
  runtime_id="$(select_ios_runtime_id "$deployment_target" best)"
fi

if [[ -z "$runtime_id" ]]; then
  echo "error: no iOS simulator runtime available" >&2
  xcrun simctl list runtimes >&2 || true
  exit 1
fi

echo "==> Using runtime ${runtime_id}"

device_type_id="$(
  xcrun simctl list devicetypes -j 2>/dev/null \
    | python3 -c "
import json, sys
data = json.load(sys.stdin)
types = data.get('devicetypes', [])
iphones = [t for t in types if t.get('productFamily') == 'iPhone']
preferred = ('iPhone 17', 'iPhone 16', 'iPhone 15')
for name in preferred:
    for t in iphones:
        if t.get('name') == name:
            print(t['identifier'])
            sys.exit(0)
if iphones:
    print(iphones[-1]['identifier'])
" 2>/dev/null || true
)"

if [[ -z "$device_type_id" ]]; then
  echo "error: no iPhone device type found" >&2
  exit 1
fi

udid="$(xcrun simctl create "CI iPhone" "$device_type_id" "$runtime_id")"
echo "==> Created simulator $udid"

xcrun simctl boot "$udid" 2>/dev/null || true
xcrun simctl bootstatus "$udid" -b

dest="platform=iOS Simulator,id=${udid}"
if ! wait_for_scheme_destination "$dest"; then
  echo "error: xcodebuild does not accept destination after boot: $dest" >&2
  xcodebuild -showdestinations -project superDemoApp.xcodeproj -scheme superDemoApp 2>&1 | head -30 >&2 || true
  xcrun simctl list devices available >&2 || true
  exit 1
fi

export CI_SIMULATOR_DEST="$dest"
if [[ -n "${GITHUB_ENV:-}" ]]; then
  echo "CI_SIMULATOR_DEST=${dest}" >>"${GITHUB_ENV}"
fi
echo "==> CI simulator ready ($dest)"
