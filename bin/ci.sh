#!/usr/bin/env bash
# Local full proof: same lint, iPhone test, and iPad/Mac build lanes as GitHub Actions.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

export PATH="/opt/homebrew/bin:/usr/local/bin:${PATH}"
export CI=true

echo "==> Swift lint"
./bin/lint.sh

echo "==> Markdown lint"
./bin/lint-markdown.sh

echo "==> Common issue checks"
./tool/check_common_issues.sh

if [[ "${CI:-}" == "true" && -z "${CI_SIMULATOR_DEST:-}" ]]; then
  ./tool/ensure_ci_simulator.sh
fi

if [[ "${CI_SKIP_PLATFORM_BUILDS:-0}" == "1" ]]; then
  echo "info: skipping iPad/Mac builds because CI_SKIP_PLATFORM_BUILDS=1"
  ./bin/ci-iphone-test.sh
else
  # GHA: iPad build before tests — post-test `build` often loses iOS Simulator destinations.
  if [[ "${CI:-}" == "true" ]]; then
    ./bin/ci-platform-builds.sh
  fi
  ./bin/ci-iphone-test.sh
  if [[ "${CI:-}" != "true" ]]; then
    ./bin/ci-platform-builds.sh
  fi
fi

echo "CI checks passed."
