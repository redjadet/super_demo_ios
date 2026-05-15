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

existing_udid="$(iphone_udid_from_simctl 2>/dev/null || true)"
if [[ -n "$existing_udid" ]]; then
  dest="platform=iOS Simulator,id=${existing_udid}"
  if destination_valid_for_scheme "$dest"; then
    echo "==> CI simulator already available ($dest)"
    exit 0
  fi
fi

echo "==> No available iPhone simulator; creating one for CI"

runtime_id="$(
  xcrun simctl list runtimes -j 2>/dev/null \
    | python3 -c "
import json, sys
data = json.load(sys.stdin)
runtimes = data.get('runtimes', [])
ios = [
    r for r in runtimes
    if r.get('isAvailable') and 'iOS' in r.get('name', '')
]
ios.sort(key=lambda r: r.get('version', ''), reverse=True)
if not ios:
    sys.exit(1)
print(ios[0]['identifier'])
" 2>/dev/null || true
)"

if [[ -z "$runtime_id" ]]; then
  echo "error: no available iOS simulator runtime found" >&2
  xcrun simctl list runtimes >&2 || true
  exit 1
fi

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

if ! iphone_udid_from_simctl >/dev/null; then
  echo "error: simulator created but still not listed as available" >&2
  xcrun simctl list devices available >&2 || true
  exit 1
fi

dest="$(resolve_iphone_destination)"
if ! destination_valid_for_scheme "$dest"; then
  echo "error: xcodebuild does not accept destination: $dest" >&2
  xcodebuild -showdestinations -project superDemoApp.xcodeproj -scheme superDemoApp 2>&1 | head -30 >&2 || true
  exit 1
fi

echo "==> CI simulator ready ($dest)"
