#!/usr/bin/env bash
# Newest iOS Simulator runtime + iPhone UDID selection (CI and local resolution).
set -euo pipefail

ios_simulator_sdk_version() {
  xcrun --show-sdk-version --sdk iphonesimulator 2>/dev/null || true
}

# Prints newest available iOS simulator runtime identifier (highest version).
select_newest_ios_runtime_id() {
  xcrun simctl list runtimes -j 2>/dev/null \
    | python3 -c "
import json, sys

def version_tuple(version):
    nums = [int(x) for x in version.split('.') if x.isdigit()]
    while len(nums) < 3:
        nums.append(0)
    return tuple(nums[:3])

data = json.load(sys.stdin)
ios = [
    r for r in data.get('runtimes', [])
    if r.get('isAvailable') and 'iOS' in r.get('name', '')
]
if not ios:
    sys.exit(1)
ios.sort(key=lambda r: version_tuple(r.get('version', '0')), reverse=True)
print(ios[0]['identifier'])
" 2>/dev/null || true
}

# Prints runtime version string (e.g. 26.5) for a runtime identifier.
ios_runtime_version() {
  local runtime_id="$1"
  xcrun simctl list runtimes -j 2>/dev/null \
    | python3 -c "
import json, sys
runtime_id = sys.argv[1]
data = json.load(sys.stdin)
for r in data.get('runtimes', []):
    if r.get('identifier') == runtime_id:
        print(r.get('version', ''))
        sys.exit(0)
sys.exit(1)
" "$runtime_id" 2>/dev/null || true
}

# Prints UDID of preferred iPhone on runtime_id, or empty.
find_iphone_udid_on_runtime() {
  local runtime_id="$1"
  xcrun simctl list devices -j 2>/dev/null \
    | python3 -c "
import json, sys

runtime_id = sys.argv[1]
preferred = ('iPhone 17', 'iPhone 16', 'iPhone 15')
data = json.load(sys.stdin)
devices = data.get('devices', {}).get(runtime_id, [])
iphones = [d for d in devices if d.get('isAvailable') and 'iPhone' in d.get('name', '')]
if not iphones:
    sys.exit(1)
booted = [d for d in iphones if d.get('state') == 'Booted']
pool = booted or iphones
for name in preferred:
    for d in pool:
        if d.get('name') == name:
            print(d['udid'])
            sys.exit(0)
print(pool[0]['udid'])
" "$runtime_id" 2>/dev/null || true
}

find_iphone_udid_on_newest_runtime() {
  local runtime_id
  runtime_id="$(select_newest_ios_runtime_id)" || return 1
  find_iphone_udid_on_runtime "$runtime_id"
}

select_preferred_iphone_device_type_id() {
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
sys.exit(1)
" 2>/dev/null || true
}

# Ensures simctl has a runtime at least as new as the active iphonesimulator SDK.
ensure_ios_runtime_matches_sdk() {
  local sdk runtime_id runtime_version
  sdk="$(ios_simulator_sdk_version)"
  [[ -n "$sdk" ]] || return 0

  runtime_id="$(select_newest_ios_runtime_id)" || true
  if [[ -z "$runtime_id" ]]; then
    echo "==> No iOS simulator runtime; downloading iOS platform for SDK ${sdk}"
    xcodebuild -downloadPlatform iOS
    return 0
  fi

  runtime_version="$(ios_runtime_version "$runtime_id")"
  local needs_download
  needs_download="$(
    python3 -c "
import sys

def vt(v):
    nums = [int(x) for x in v.split('.') if x.isdigit()]
    while len(nums) < 3:
        nums.append(0)
    return tuple(nums[:3])

sdk = sys.argv[1]
runtime = sys.argv[2]
print('yes' if vt(sdk) > vt(runtime) else 'no')
" "$sdk" "$runtime_version"
  )"

  if [[ "$needs_download" == "yes" ]]; then
    echo "==> Newest runtime iOS ${runtime_version} is older than SDK ${sdk}; downloading iOS platform"
    xcodebuild -downloadPlatform iOS
  fi
}
