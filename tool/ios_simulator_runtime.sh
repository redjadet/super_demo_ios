#!/usr/bin/env bash
# Newest iOS Simulator runtime + iPhone UDID selection (CI and local resolution).
set -euo pipefail

ios_simulator_sdk_version() {
  xcrun --show-sdk-version --sdk iphonesimulator 2>/dev/null || true
}

# Prints newest available iOS simulator runtime identifier (highest version).
select_newest_ios_runtime_id() {
  select_ios_runtime_ids_newest_first | head -n1
}

# Prints available iOS runtime identifiers, newest version first.
select_ios_runtime_ids_newest_first() {
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
for r in ios:
    print(r['identifier'])
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
# Skips exotic form factors (Duo/Fold/…) — they are not reliable xcodebuild destinations.
find_iphone_udid_on_runtime() {
  local runtime_id="$1"
  xcrun simctl list devices -j 2>/dev/null \
    | python3 -c "
import json, re, sys

runtime_id = sys.argv[1]
preferred = (
    'iPhone 18 Pro Max', 'iPhone 18 Pro', 'iPhone 18 Plus', 'iPhone 18',
    'iPhone 17 Pro Max', 'iPhone 17 Pro', 'iPhone 17 Plus', 'iPhone 17',
    'iPhone 16 Pro Max', 'iPhone 16 Pro', 'iPhone 16 Plus', 'iPhone 16',
    'iPhone 15 Pro Max', 'iPhone 15 Pro', 'iPhone 15 Plus', 'iPhone 15',
)
exotic_markers = ('Duo', 'Fold', 'Air')

def is_standard_iphone(name):
    if not name or 'iPhone' not in name:
        return False
    if any(m in name for m in exotic_markers):
        return False
    if name in preferred:
        return True
    if re.match(r'^iPhone \d+( Pro Max| Pro| Plus)?$', name):
        return True
    if re.match(r'^iPhone SE( \(\d(st|nd|rd|th) generation\))?$', name):
        return True
    return False

def phone_rank(name):
    m = re.search(r'iPhone (\d+)', name or '')
    gen = int(m.group(1)) if m else 0
    if 'Pro Max' in name:
        tier = 3
    elif 'Pro' in name:
        tier = 2
    elif 'Plus' in name:
        tier = 1
    elif name.startswith('iPhone SE'):
        tier = -1
    else:
        tier = 0
    return (gen, tier)

data = json.load(sys.stdin)
devices = data.get('devices', {}).get(runtime_id, [])
iphones = [
    d for d in devices
    if d.get('isAvailable') and is_standard_iphone(d.get('name', ''))
]
if not iphones:
    sys.exit(1)
booted = [d for d in iphones if d.get('state') == 'Booted']
pool = booted or iphones
for name in preferred:
    for d in pool:
        if d.get('name') == name:
            print(d['udid'])
            sys.exit(0)

pool.sort(key=lambda d: phone_rank(d.get('name', '')), reverse=True)
print(pool[0]['udid'])
" "$runtime_id" 2>/dev/null || true
}

find_iphone_udid_on_newest_runtime() {
  local runtime_id udid
  while IFS= read -r runtime_id; do
    [[ -n "$runtime_id" ]] || continue
    udid="$(find_iphone_udid_on_runtime "$runtime_id" || true)"
    if [[ -n "$udid" ]]; then
      printf '%s\n' "$udid"
      return 0
    fi
  done < <(select_ios_runtime_ids_newest_first)
  return 1
}

# Prints UDID of preferred iPad on runtime_id, or empty.
find_ipad_udid_on_runtime() {
  local runtime_id="$1"
  xcrun simctl list devices -j 2>/dev/null \
    | python3 -c "
import json, sys

runtime_id = sys.argv[1]
preferred = (
    'iPad Pro 13-inch (M5)',
    'iPad Pro 11-inch (M5)',
    'iPad Pro 13-inch (M4)',
    'iPad Pro 11-inch (M4)',
    'iPad Air 13-inch (M3)',
    'iPad (A16)',
)
data = json.load(sys.stdin)
devices = data.get('devices', {}).get(runtime_id, [])
ipads = [d for d in devices if d.get('isAvailable') and 'iPad' in d.get('name', '')]
if not ipads:
    sys.exit(1)
for name in preferred:
    for d in ipads:
        if d.get('name') == name:
            print(d['udid'])
            sys.exit(0)
print(ipads[0]['udid'])
" "$runtime_id" 2>/dev/null || true
}

find_ipad_udid_on_newest_runtime() {
  local runtime_id
  runtime_id="$(select_newest_ios_runtime_id)" || return 1
  find_ipad_udid_on_runtime "$runtime_id"
}

# Prints xcodebuild destination for a booted simulator UDID (id=, then name+OS).
scheme_destination_for_udid() {
  local udid="$1"
  [[ "$udid" =~ ^[0-9A-F-]{36}$ ]] || return 1
  local by_name
  by_name="$(
    xcrun simctl list devices -j 2>/dev/null \
      | python3 -c "
import json, sys

udid = sys.argv[1]
data = json.load(sys.stdin)
name = ''
runtime_id = ''
for rid, devices in data.get('devices', {}).items():
    for d in devices:
        if d.get('udid') == udid:
            name = d.get('name', '')
            runtime_id = rid
            break
    if name:
        break
if not name or not runtime_id:
    sys.exit(1)
runtime_version = ''
for r in data.get('runtimes', []):
    if r.get('identifier') == runtime_id:
        runtime_version = r.get('version', '')
        break
if not runtime_version:
    sys.exit(1)
print(f'platform=iOS Simulator,name={name},OS={runtime_version}')
" "$udid" 2>/dev/null || true
  )"
  if [[ -n "$by_name" ]]; then
    printf '%s\n' "$by_name"
    return 0
  fi
  printf 'platform=iOS Simulator,id=%s\n' "$udid"
}

select_preferred_ipad_device_type_id() {
  xcrun simctl list devicetypes -j 2>/dev/null \
    | python3 -c "
import json, sys
data = json.load(sys.stdin)
types = data.get('devicetypes', [])
ipads = [t for t in types if t.get('productFamily') == 'iPad']
preferred = (
    'iPad Pro 13-inch (M5)',
    'iPad Pro 11-inch (M5)',
    'iPad Pro 13-inch (M4)',
    'iPad Pro 11-inch (M4)',
    'iPad Air 13-inch (M3)',
    'iPad (A16)',
)
for name in preferred:
    for t in ipads:
        if t.get('name') == name:
            print(t['identifier'])
            sys.exit(0)
if ipads:
    print(ipads[-1]['identifier'])
sys.exit(1)
" 2>/dev/null || true
}

select_preferred_iphone_device_type_id() {
  xcrun simctl list devicetypes -j 2>/dev/null \
    | python3 -c "
import json, re, sys
data = json.load(sys.stdin)
types = data.get('devicetypes', [])
iphones = [t for t in types if t.get('productFamily') == 'iPhone']
preferred = (
    'iPhone 18 Pro Max', 'iPhone 18 Pro', 'iPhone 18 Plus', 'iPhone 18',
    'iPhone 17 Pro Max', 'iPhone 17 Pro', 'iPhone 17 Plus', 'iPhone 17',
    'iPhone 16 Pro Max', 'iPhone 16 Pro', 'iPhone 16 Plus', 'iPhone 16',
    'iPhone 15 Pro Max', 'iPhone 15 Pro', 'iPhone 15 Plus', 'iPhone 15',
)
exotic_markers = ('Duo', 'Fold', 'Air')

def is_standard_iphone(name):
    if not name or 'iPhone' not in name:
        return False
    if any(m in name for m in exotic_markers):
        return False
    if name in preferred:
        return True
    if re.match(r'^iPhone \d+( Pro Max| Pro| Plus)?$', name):
        return True
    return False

for name in preferred:
    for t in iphones:
        if t.get('name') == name:
            print(t['identifier'])
            sys.exit(0)

def phone_rank(name):
    m = re.search(r'iPhone (\d+)', name or '')
    gen = int(m.group(1)) if m else 0
    if 'Pro Max' in name:
        tier = 3
    elif 'Pro' in name:
        tier = 2
    elif 'Plus' in name:
        tier = 1
    else:
        tier = 0
    return (gen, tier)

standard = [t for t in iphones if is_standard_iphone(t.get('name', ''))]
if standard:
    standard.sort(key=lambda t: phone_rank(t.get('name', '')), reverse=True)
    print(standard[0]['identifier'])
    sys.exit(0)
sys.exit(1)
" 2>/dev/null || true
}

# Ensures an iOS simulator runtime exists. On CI, uses the newest installed runtime only
# (no platform download — GHA images often have SDK 26.5 with runtime 26.4; download hangs).
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
  if [[ "${CI:-}" == "true" ]]; then
    echo "==> CI using newest installed iOS ${runtime_version} (iphonesimulator SDK ${sdk})"
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
      echo "==> CI SDK ${sdk} > simulator runtime ${runtime_version}; downloading iOS platform (timeout 900s)" >&2
      if command -v timeout >/dev/null 2>&1; then
        refresh_xcodebuild_from_developer_dir
        timeout 900 "$XCODEBUILD" -downloadPlatform iOS \
          || echo "warning: -downloadPlatform iOS failed or timed out; continuing with runtime ${runtime_version}" >&2
      elif [[ -f "$ROOT/tool/run_with_timeout.py" ]]; then
        refresh_xcodebuild_from_developer_dir
        python3 "$ROOT/tool/run_with_timeout.py" --timeout 900 -- "$XCODEBUILD" -downloadPlatform iOS \
          || echo "warning: -downloadPlatform iOS failed or timed out; continuing with runtime ${runtime_version}" >&2
      else
        refresh_xcodebuild_from_developer_dir
        "$XCODEBUILD" -downloadPlatform iOS \
          || echo "warning: -downloadPlatform iOS failed; continuing with runtime ${runtime_version}" >&2
      fi
    fi
    return 0
  fi

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
