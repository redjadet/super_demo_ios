#!/usr/bin/env bash
# Compatibility entry point for historical references.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
exec "$ROOT/tool/check_engineering_evidence_map.sh" "$@"
