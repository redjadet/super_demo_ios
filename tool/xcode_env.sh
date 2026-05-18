#!/usr/bin/env bash
# Shared Xcode CLI resolution (source, do not execute).
set -euo pipefail

if [[ -n "${DEVELOPER_DIR:-}" && -x "${DEVELOPER_DIR}/usr/bin/xcodebuild" ]]; then
  XCODEBUILD="${DEVELOPER_DIR}/usr/bin/xcodebuild"
else
  XCODEBUILD="$(command -v xcodebuild)"
fi

if [[ -z "$XCODEBUILD" || ! -x "$XCODEBUILD" ]]; then
  echo "error: xcodebuild not found (DEVELOPER_DIR=${DEVELOPER_DIR:-unset})" >&2
  exit 1
fi
