#!/usr/bin/env bash
# Shared xcodebuild settings: treat warnings as errors (source, do not execute).
#
# Default ON for checklist / CI / local proof. Escape hatch:
#   XCODEBUILD_ALLOW_WARNINGS=1 ./bin/ci-iphone-test.sh
#
# Leave XCODEBUILD_WARNINGS_AS_ERRORS_FLAGS unset when empty so callers can
# expand with ${XCODEBUILD_WARNINGS_AS_ERRORS_FLAGS+"${XCODEBUILD_WARNINGS_AS_ERRORS_FLAGS[@]}"}
# under set -u.

unset XCODEBUILD_WARNINGS_AS_ERRORS_FLAGS

if [[ "${XCODEBUILD_ALLOW_WARNINGS:-0}" != "1" ]]; then
  XCODEBUILD_WARNINGS_AS_ERRORS_FLAGS=(
    SWIFT_TREAT_WARNINGS_AS_ERRORS=YES
    GCC_TREAT_WARNINGS_AS_ERRORS=YES
  )
fi
