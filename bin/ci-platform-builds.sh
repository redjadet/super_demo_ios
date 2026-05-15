#!/usr/bin/env bash
# Universal platform compile proof: iPad simulator + macOS (used by ci.sh and CI workflow).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

# shellcheck source=../tool/resolve_platform_destination.sh
source "$ROOT/tool/resolve_platform_destination.sh"

IPAD_DEST="$(resolve_ipad_destination)"
MAC_DEST="$(resolve_mac_destination)"

echo "==> iPad build ($IPAD_DEST)"
xcodebuild \
  -project superDemoApp.xcodeproj \
  -scheme superDemoApp \
  -destination "$IPAD_DEST" \
  -configuration Debug \
  build

echo "==> Mac build ($MAC_DEST)"
xcodebuild \
  -project superDemoApp.xcodeproj \
  -scheme superDemoApp \
  -destination "$MAC_DEST" \
  -configuration Debug \
  build

echo "Platform builds passed."
