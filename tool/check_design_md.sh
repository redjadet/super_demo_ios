#!/usr/bin/env bash
# Validate root DESIGN.md with Google's @google/design.md CLI (optional; needs Node npx).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

if [[ ! -f DESIGN.md ]]; then
  echo "missing DESIGN.md at repo root" >&2
  exit 1
fi

if ! command -v npx >/dev/null 2>&1; then
  echo "skip: npx not found (install Node to lint DESIGN.md)" >&2
  exit 0
fi

echo "Running @google/design.md lint..."
npx --yes @google/design.md lint DESIGN.md
