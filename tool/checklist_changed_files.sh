#!/usr/bin/env bash
# Collect changed paths for checklist scope routing (flutter_bloc_app parity).
# shellcheck source=checklist_scope.sh
# Source from repo root or with ROOT set.

checklist_collect_changed_files_from_worktree() {
  {
    git diff --name-only --diff-filter=ACDMRTUXB
    git diff --cached --name-only --diff-filter=ACDMRTUXB
    git ls-files --others --exclude-standard
  }
}

checklist_collect_changed_files_from_ci() {
  local event_name="${GITHUB_EVENT_NAME:-}"

  if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1 || [ -z "${CI:-}" ]; then
    return 1
  fi

  case "$event_name" in
    pull_request|pull_request_target)
      if [[ "${GITHUB_REF:-}" == refs/pull/*/merge ]] &&
        git rev-parse --verify HEAD^1 >/dev/null 2>&1; then
        git diff --name-only --diff-filter=ACDMRTUXB HEAD^1..HEAD
        return 0
      fi

      if [ -n "${GITHUB_BASE_REF:-}" ]; then
        local remote_base="origin/$GITHUB_BASE_REF"
        local merge_base=""
        git fetch --no-tags --depth=50 origin \
          "+refs/heads/$GITHUB_BASE_REF:refs/remotes/origin/$GITHUB_BASE_REF" >/dev/null 2>&1 || true
        if git rev-parse --verify "$remote_base" >/dev/null 2>&1; then
          merge_base="$(git merge-base HEAD "$remote_base" 2>/dev/null || true)"
          if [ -n "$merge_base" ]; then
            git diff --name-only --diff-filter=ACDMRTUXB "$merge_base"...HEAD
            return 0
          fi
        fi
      fi
      ;;
    push|merge_group)
      if git rev-parse --verify HEAD^ >/dev/null 2>&1; then
        git diff --name-only --diff-filter=ACDMRTUXB HEAD^..HEAD
      else
        git show --pretty='' --name-only --diff-filter=ACDMRTUXB HEAD
      fi
      return 0
      ;;
  esac

  return 1
}

# Populates global array CHECKLIST_CHANGED_FILES.
checklist_collect_changed_files() {
  CHECKLIST_CHANGED_FILES=()
  if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    return 0
  fi

  local file
  while IFS= read -r file; do
    [ -z "$file" ] && continue
    CHECKLIST_CHANGED_FILES+=("$file")
  done < <(
    {
      if [ -n "${CI:-}" ] && checklist_collect_changed_files_from_ci; then
        :
      else
        checklist_collect_changed_files_from_worktree
      fi
    } | sort -u | sed '/^$/d'
  )
}

checklist_is_docs_only_change_set() {
  # shellcheck source=checklist_scope.sh
  source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/checklist_scope.sh"

  if [ "${#CHECKLIST_CHANGED_FILES[@]}" -eq 0 ]; then
    return 1
  fi
  if ! checklist_docs_only_event_allowed; then
    return 1
  fi
  checklist_docs_only_paths "${CHECKLIST_CHANGED_FILES[@]}"
}
