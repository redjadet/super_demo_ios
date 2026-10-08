#!/usr/bin/env bash
# Shared version pins for lint tools (source from bin/lint.sh and checks).
# Keep Brewfile comments and docs/code-style.md aligned when bumping.
# shellcheck disable=SC2034
EXPECTED_SWIFTFORMAT_VERSION="0.63.1"
EXPECTED_SWIFTLINT_VERSION="0.65.1"

# Optional agent-host tools (documented pins; not enforced by CI / checklist).
# See docs/agent_dev_tools.md — install separately; wrappers soft-fail if absent.
EXPECTED_XCSIFT_VERSION="1.5.2"
EXPECTED_SF_SYMBOLS_CASK_VERSION="27" # brew cask sf-symbols
# RocketTrace: no Homebrew pin — app + CLI from https://rockettrace.app/
