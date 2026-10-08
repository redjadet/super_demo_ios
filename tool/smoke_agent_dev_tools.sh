#!/usr/bin/env bash
# Non-interactive smoke for optional agent Mac/Xcode tool wrappers.
# Passes when wrappers are present and missing-tool paths exit 2.
# Does not fail the lane solely because optional host tools are absent.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

export PATH="/opt/homebrew/bin:/usr/local/bin:${PATH}"

failures=0
section() { printf '\n==> %s\n' "$1"; }
pass() { echo "ok: $1"; }
fail() { echo "error: $1" >&2; failures=$((failures + 1)); }

section "Wrapper executables"
for rel in bin/xcsift-run bin/sfsymbols bin/rockettrace; do
  if [[ -x "$ROOT/$rel" ]]; then
    pass "$rel executable"
  else
    fail "$rel missing or not executable"
  fi
done

section "Help paths (no host tools required)"
for rel in bin/xcsift-run bin/sfsymbols bin/rockettrace; do
  if "$ROOT/$rel" --help >/dev/null 2>&1; then
    pass "$rel --help"
  else
    fail "$rel --help failed"
  fi
done

section "Missing-tool exit codes (forced)"
# Force missing binaries via PATH / env overrides.
if env PATH="/usr/bin:/bin" "$ROOT/bin/xcsift-run" /bin/echo hi >/dev/null 2>&1; then
  fail "xcsift-run should exit non-zero when xcsift missing"
else
  status=$?
  if [[ "$status" -eq 2 ]]; then
    pass "xcsift-run exit 2 when xcsift missing"
  else
    fail "xcsift-run expected exit 2 when missing, got $status"
  fi
fi

if env PATH="/usr/bin:/bin" SFSYMBOLS_BIN=/nonexistent/sfsymbols \
  "$ROOT/bin/sfsymbols" search heart >/dev/null 2>&1; then
  fail "sfsymbols should exit non-zero when CLI missing"
else
  status=$?
  if [[ "$status" -eq 2 ]]; then
    pass "sfsymbols exit 2 when CLI missing"
  else
    fail "sfsymbols expected exit 2 when missing, got $status"
  fi
fi

if env PATH="/usr/bin:/bin" ROCKETTRACE_BIN=/nonexistent/rockettrace \
  "$ROOT/bin/rockettrace" status >/dev/null 2>&1; then
  fail "rockettrace should exit non-zero when CLI missing"
else
  status=$?
  if [[ "$status" -eq 2 ]]; then
    pass "rockettrace exit 2 when CLI missing"
  else
    fail "rockettrace expected exit 2 when missing, got $status"
  fi
fi

section "Optional host tools (informational)"
if command -v xcsift >/dev/null 2>&1; then
  ver="$(xcsift --version 2>/dev/null || true)"
  pass "xcsift present${ver:+ ($ver)}"
  if printf 'Build succeeded\n' | xcsift >/dev/null 2>&1; then
    pass "xcsift parses sample line"
  else
    fail "xcsift failed on sample 'Build succeeded'"
  fi
else
  echo "skip: xcsift not installed (brew install xcsift)"
fi

if [[ -x "/Applications/SF Symbols.app/Contents/Executables/sfsymbols" ]] \
  || command -v sfsymbols >/dev/null 2>&1; then
  if "$ROOT/bin/sfsymbols" search heart --min-platform iOS26 >/dev/null 2>&1; then
    pass "sfsymbols search heart"
  else
    # Some catalog queries may return empty without failing; accept --help already.
    echo "warn: sfsymbols search returned non-zero (catalog/flags may differ); wrapper still OK"
  fi
else
  echo "skip: SF Symbols 27 not installed (brew install --cask sf-symbols)"
fi

if command -v rockettrace >/dev/null 2>&1 || [[ -n "${ROCKETTRACE_BIN:-}" ]]; then
  if "$ROOT/bin/rockettrace" status >/dev/null 2>&1; then
    pass "rockettrace status"
  else
    echo "warn: rockettrace present but status failed (is RocketTrace.app running?)"
  fi
else
  echo "skip: rockettrace not installed (https://rockettrace.app/ → Settings → CLI & Agent)"
fi

section "Summary"
if [[ "$failures" -gt 0 ]]; then
  echo "FAILED: $failures check(s)" >&2
  exit 1
fi
echo "PASSED: agent dev tools smoke"
exit 0
