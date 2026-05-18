#!/usr/bin/env bash
# Catch Swift mistakes agents repeat (compile-time or review-time), beyond indent/format.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APP="$ROOT/superDemoApp"
TESTS="$ROOT/superDemoAppTests"

failed=0

fail() {
  echo "error: $1" >&2
  failed=1
}

section() {
  printf '==> %s\n' "$1"
}

section "MainActor deinit must not touch isolated state"
# deinit is nonisolated; refreshTask on @MainActor models fails Swift 6 compile.
matches="$(
  rg -n --glob '*.swift' -U \
    'deinit\s*\{[^\}]{0,400}\brefreshTask\b' \
    "$APP" "$TESTS" 2>/dev/null || true
)"
if [[ -n "$matches" ]]; then
  echo "$matches" >&2
  fail "cancel refresh work in .onDisappear { cancelRefresh() }, not deinit — see docs/agent_swift_guards.md"
fi

section "UIKit teardown must not run from deinit"
matches="$(
  rg -n --glob '*.swift' -U \
    'deinit\s*\{[^\}]{0,400}\b(collectionView|prefetchDataSource|navigationController)\b' \
    "$APP" 2>/dev/null || true
)"
if [[ -n "$matches" ]]; then
  echo "$matches" >&2
  fail "UIKit in deinit is unsafe off main thread — use teardown() from dismantleUIViewController / viewDidDisappear"
fi

section "AppURLSession must not allocate per call"
if [[ -f "$APP/Shared/Networking/AppURLSession.swift" ]]; then
  if rg -n 'func makeDefault\(\)[^\n]*URLSession\s*\(\s*configuration' "$APP/Shared/Networking/AppURLSession.swift" \
    >/dev/null 2>&1
  then
    fail "AppURLSession.makeDefault() must return a shared URLSession, not URLSession(configuration:) each call"
  fi
fi

if [[ "$failed" -ne 0 ]]; then
  echo "See docs/agent_swift_guards.md" >&2
  exit 1
fi
