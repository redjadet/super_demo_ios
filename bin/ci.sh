#!/usr/bin/env bash
# Local full proof: same lanes as GitHub Actions (via Fastlane).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

export PATH="/opt/homebrew/bin:/usr/local/bin:${PATH}"
export CI=true

exec ./bin/fastlane-run ci
