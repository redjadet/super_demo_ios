#!/usr/bin/env bash
# Contract tests for docs-only scope routing (flutter_bloc_app parity).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck source=checklist_scope.sh
source "$ROOT/tool/checklist_scope.sh"

failures=0
fail() {
  echo "error: $1" >&2
  failures=$((failures + 1))
}

section() { printf '\n==> %s\n' "$1"; }

section "docs-only paths allowlist"
if ! checklist_docs_only_paths README.md docs/testing.md llms.txt; then
  fail "expected markdown + llms.txt to be docs-only"
fi
if checklist_docs_only_paths README.md bin/checklist; then
  fail "bin/checklist must not be docs-only"
fi
if checklist_docs_only_paths docs/foo.swift; then
  fail "swift under docs/ must not be docs-only"
fi
if checklist_docs_only_paths .github/workflows/ci.yml; then
  fail "workflow changes must not be docs-only"
fi
if checklist_docs_only_paths; then
  fail "empty path set must not be docs-only"
fi

section "event gate"
(
  unset CI GITHUB_EVENT_NAME
  checklist_docs_only_event_allowed || fail "local (no CI) must allow docs-only"
)
(
  export CI=true
  export GITHUB_EVENT_NAME=pull_request
  checklist_docs_only_event_allowed || fail "pull_request must allow docs-only"
)
(
  export CI=true
  export GITHUB_EVENT_NAME=push
  if checklist_docs_only_event_allowed; then
    fail "push must not allow docs-only"
  fi
)

section "print-scope CLI"
scope_out="$(cd "$ROOT" && ./bin/checklist --print-scope)"
case "$scope_out" in
  docs_only=true|docs_only=false) ;;
  *) fail "invalid --print-scope output: $scope_out" ;;
esac

if ((failures > 0)); then
  echo "checklist scope contract failed ($failures)" >&2
  exit 1
fi
echo "checklist scope contract passed."
