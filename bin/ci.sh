#!/usr/bin/env bash
# Local CI parity: lint, build, unit tests (matches .github/workflows/ci.yml).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

export PATH="/opt/homebrew/bin:/usr/local/bin:${PATH}"
export CI=true

# arm64 simulator is faster/reliable on Apple Silicon; override with CI_SIMULATOR_DEST.
SIMULATOR_DEST="${CI_SIMULATOR_DEST:-platform=iOS Simulator,name=iPhone 17,OS=26.5}"

echo "==> Swift lint"
./bin/lint.sh

echo "==> Markdown lint"
./bin/lint-markdown.sh

echo "==> Build"
xcodebuild \
  -project superDemoApp.xcodeproj \
  -scheme superDemoApp \
  -destination "$SIMULATOR_DEST" \
  -configuration Debug \
  build

echo "==> Test"
xcodebuild \
  -project superDemoApp.xcodeproj \
  -scheme superDemoApp \
  -destination "$SIMULATOR_DEST" \
  -configuration Debug \
  test

echo "CI checks passed."
