#!/bin/bash
# Xcode build phase — delegates to bin/lint.sh (SwiftLint strict + SwiftFormat lint).
set -euo pipefail

export PATH="/opt/homebrew/bin:/usr/local/bin:${PATH}"
cd "${SRCROOT}"

if [[ "${CI:-}" != "true" && "${RUN_LINT_STRICT:-}" != "1" ]]; then
  if ! command -v swiftlint >/dev/null || ! command -v swiftformat >/dev/null; then
    echo "warning: SwiftLint/SwiftFormat not installed — skipping lint build phase."
    echo "warning: Install with: brew bundle --file Brewfile"
    if [[ -n "${SCRIPT_OUTPUT_FILE_0:-}" ]]; then
      echo "SKIPPED" > "${SCRIPT_OUTPUT_FILE_0}"
    fi
    exit 0
  fi
fi

"${SRCROOT}/bin/lint.sh"

if [[ -n "${SCRIPT_OUTPUT_FILE_0:-}" ]]; then
  echo "SUCCESS" > "${SCRIPT_OUTPUT_FILE_0}"
fi
