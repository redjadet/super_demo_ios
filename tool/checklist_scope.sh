#!/usr/bin/env bash
# Shared docs-only path rule for local checklist + GHA `changes` job.
# Mirror of flutter_bloc_app/tool/checklist_scope.sh (narrow extension allowlist).
# Empty or unrecognized scopes must take the full CI route.

checklist_docs_only_event_allowed() {
  # Push / merge_group one-parent diffs can omit earlier commits in a batch.
  # Keep those events on the full route (flutter_bloc_app parity).
  [ -z "${CI:-}" ] || [ "${GITHUB_EVENT_NAME:-}" = "pull_request" ]
}

checklist_docs_only_paths() {
  [ "$#" -gt 0 ] || return 1

  local file
  for file in "$@"; do
    case "$file" in
      *.md|*.mdx|*.rst|*.adoc|\
      llms.txt)
        ;;
      *)
        return 1
        ;;
    esac
  done
}
