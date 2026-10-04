#!/usr/bin/env bash
# Shared xcodebuild settings: treat warnings as errors (source, do not execute).
#
# Warnings-as-errors live on the Xcode *project* configurations
# (`SWIFT_TREAT_WARNINGS_AS_ERRORS` / `GCC_TREAT_WARNINGS_AS_ERRORS` in
# `superDemoApp.xcodeproj`). Do **not** pass those as xcodebuild CLI overrides:
# CLI settings apply to SPM package targets too, and Xcode already adds
# `-suppress-warnings` for packages → conflict:
#   error: Conflicting options '-warnings-as-errors' and '-suppress-warnings'
#
# Escape hatch (clears project-level treat-as-error for a local build):
#   XCODEBUILD_ALLOW_WARNINGS=1 ./bin/ci-iphone-test.sh
#
# Leave XCODEBUILD_WARNINGS_AS_ERRORS_FLAGS unset when empty so callers can
# expand with ${XCODEBUILD_WARNINGS_AS_ERRORS_FLAGS+"${XCODEBUILD_WARNINGS_AS_ERRORS_FLAGS[@]}"}
# under set -u.

unset XCODEBUILD_WARNINGS_AS_ERRORS_FLAGS

if [[ "${XCODEBUILD_ALLOW_WARNINGS:-0}" == "1" ]]; then
  # Explicit override for local experimentation — still avoids SPM CLI conflict
  # when not set; when allow-warnings is on, force NO on the whole build.
  XCODEBUILD_WARNINGS_AS_ERRORS_FLAGS=(
    SWIFT_TREAT_WARNINGS_AS_ERRORS=NO
    GCC_TREAT_WARNINGS_AS_ERRORS=NO
  )
fi
