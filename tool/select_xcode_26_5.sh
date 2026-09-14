#!/usr/bin/env bash
# Compatibility wrapper — prefer tool/select_xcode.sh going forward.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck source=select_xcode.sh
source "$ROOT/tool/select_xcode.sh"
