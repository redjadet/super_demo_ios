#!/usr/bin/env bash
# Shared xcodebuild settings for nested command sandboxes.
#
# Codex/Xcode Coding Assistant runs shell commands inside a seatbelt sandbox.
# Swift macro expansion also invokes sandboxed helper processes; nested sandbox
# setup can fail with "swift-plugin-server produced malformed response" unless
# the Swift compiler sandbox is disabled for this command.

set -euo pipefail

XCODEBUILD_SANDBOX_FLAGS=()

if [[ -n "${CODEX_SANDBOX:-}" || "${XCODEBUILD_DISABLE_SWIFT_SANDBOX:-0}" == "1" ]]; then
  XCODEBUILD_SANDBOX_FLAGS=(
    ENABLE_USER_SCRIPT_SANDBOXING=NO
    "OTHER_SWIFT_FLAGS=\$(inherited) -disable-sandbox"
  )
fi
