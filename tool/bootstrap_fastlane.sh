#!/usr/bin/env bash
# Install Bundler gems for Fastlane (local + CI via ruby/setup-ruby bundler-cache).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

export PATH="/opt/homebrew/opt/ruby/bin:/opt/homebrew/bin:/usr/local/bin:${PATH}"

if ! command -v bundle >/dev/null 2>&1; then
  echo "error: install Ruby and Bundler (e.g. brew install ruby)" >&2
  exit 1
fi

bundle config set --local path vendor/bundle
bundle install
chmod +x bin/fastlane-run
echo "Fastlane ready: ./bin/fastlane-run lanes"
