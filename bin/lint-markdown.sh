#!/usr/bin/env bash
# Lint Markdown under superDemoApp/ (markdownlint-cli2).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

if ! command -v npx >/dev/null 2>&1; then
  echo "error: npx not found (Node.js required for markdownlint-cli2)" >&2
  exit 1
fi

echo "==> markdownlint"
# Vendored skills under .agents/ are not project docs; lint repo docs only.
npx --yes markdownlint-cli2 "**/*.md" "#.agents/**"

echo "Markdown lint passed."
