#!/usr/bin/env bash
# Prune stale agent worktrees and merged topic branches (dry-run default).
#
# Lean iOS port of Flutter tool/prune_git_stale.sh spirit — not a full gh suite.
# Prefers safe local cleanup under .worktrees/ and merged cursor/* locals.
#
# Requires: git. Optional: gh (for MERGED PR head detection).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

REMOTE="origin"
BASE_REF=""
DRY_RUN=1
DO_WORKTREES=1
DO_LOCALS=1
DO_GH_MERGED=1
KEEP_BRANCHES=()

usage() {
  cat <<'EOF'
tool/prune_git_stale.sh — prune merged topic branches + stale .worktrees.

Default: dry-run. Pass --apply to delete.

Always:
  git fetch --prune <remote> (best effort)

Then (preview or apply):
  - local topic branches already merged into base (skips main/master/develop/current)
  - optional: gh MERGED PR heads (when gh available)
  - extra worktrees under .worktrees/ whose HEAD is ancestor of base

Options:
  --remote NAME     Remote (default: origin)
  --base REF        Base after fetch (default: <remote>/main)
  --keep NAME       Keep branch (repeatable)
  --skip-worktrees  Do not remove worktrees
  --skip-locals     Do not delete local branches
  --skip-gh         Do not query gh for MERGED PRs
  --dry-run         Preview only (default)
  --apply           Perform deletions
  -h, --help        Help

Examples:
  ./bin/prune-git-stale
  ./bin/prune-git-stale --apply
EOF
}

die() { echo "error: $*" >&2; exit 2; }
info() { printf '%s\n' "$*"; }

while [[ $# -gt 0 ]]; do
  case "$1" in
    --remote) REMOTE="${2:-}"; shift 2 ;;
    --base) BASE_REF="${2:-}"; shift 2 ;;
    --keep) KEEP_BRANCHES+=("${2:-}"); shift 2 ;;
    --skip-worktrees) DO_WORKTREES=0; shift ;;
    --skip-locals) DO_LOCALS=0; shift ;;
    --skip-gh) DO_GH_MERGED=0; shift ;;
    --dry-run) DRY_RUN=1; shift ;;
    --apply) DRY_RUN=0; shift ;;
    -h|--help) usage; exit 0 ;;
    *) die "unknown option: $1" ;;
  esac
done

CURRENT_BRANCH="$(git rev-parse --abbrev-ref HEAD)"

is_keep() {
  local b="$1" k
  for k in "${KEEP_BRANCHES[@]+"${KEEP_BRANCHES[@]}"}"; do
    [[ "$b" == "$k" ]] && return 0
  done
  return 1
}

is_protected() {
  local b="$1"
  case "$b" in
    main|master|develop|HEAD) return 0 ;;
  esac
  [[ "$b" == "$CURRENT_BRANCH" ]] && return 0
  is_keep "$b" && return 0
  return 1
}

info "prune_git_stale: fetch --prune $REMOTE (best effort)"
git fetch --prune "$REMOTE" 2>/dev/null || info "warning: fetch failed; continuing with local refs"

if [[ -z "$BASE_REF" ]]; then
  if git show-ref --verify --quiet "refs/remotes/${REMOTE}/main"; then
    BASE_REF="${REMOTE}/main"
  else
    BASE_REF="$(git symbolic-ref -q "refs/remotes/${REMOTE}/HEAD" 2>/dev/null | sed "s#^refs/remotes/${REMOTE}/#${REMOTE}/#" || true)"
  fi
fi
[[ -n "$BASE_REF" ]] || die "could not resolve base ref"
info "base=$BASE_REF current=$CURRENT_BRANCH dry_run=$DRY_RUN"

merged_locals=()
if [[ "$DO_LOCALS" -eq 1 ]]; then
  while IFS= read -r branch; do
    [[ -z "$branch" ]] && continue
    branch="${branch#\* }"
    branch="$(echo "$branch" | awk '{print $1}')"
    is_protected "$branch" && continue
    if git merge-base --is-ancestor "$branch" "$BASE_REF" 2>/dev/null; then
      merged_locals+=("$branch")
    fi
  done < <(git for-each-ref --format='%(refname:short)' refs/heads/)
fi

if [[ "$DO_GH_MERGED" -eq 1 ]] && command -v gh >/dev/null 2>&1; then
  while IFS= read -r head; do
    [[ -z "$head" ]] && continue
    is_protected "$head" && continue
    if git show-ref --verify --quiet "refs/heads/$head"; then
      merged_locals+=("$head")
    fi
  done < <(gh pr list --state merged --limit 50 --json headRefName --jq '.[].headRefName' 2>/dev/null || true)
fi

# uniq without mapfile (macOS /bin/bash 3.2)
if [[ ${#merged_locals[@]} -gt 0 ]]; then
  uniq_merged=()
  while IFS= read -r line; do
    [[ -n "$line" ]] && uniq_merged+=("$line")
  done < <(printf '%s\n' "${merged_locals[@]}" | awk 'NF && !seen[$0]++')
  merged_locals=("${uniq_merged[@]}")
fi

stale_worktrees=()
if [[ "$DO_WORKTREES" -eq 1 ]]; then
  while IFS= read -r line; do
    wt_path="$(echo "$line" | awk '{print $1}')"
    [[ -z "$wt_path" || "$wt_path" == "$ROOT" ]] && continue
    case "$wt_path" in
      "$ROOT"/.worktrees/*|*/superDemoApp-wt-*) ;;
      *) continue ;;
    esac
    head_sha="$(git -C "$wt_path" rev-parse HEAD 2>/dev/null || true)"
    [[ -n "$head_sha" ]] || continue
    if git merge-base --is-ancestor "$head_sha" "$BASE_REF" 2>/dev/null; then
      stale_worktrees+=("$wt_path")
    fi
  done < <(git worktree list --porcelain | awk '/^worktree /{print $2}')
fi

info "merged local branches (${#merged_locals[@]}):"
for b in "${merged_locals[@]+"${merged_locals[@]}"}"; do info "  $b"; done
info "stale worktrees (${#stale_worktrees[@]}):"
for w in "${stale_worktrees[@]+"${stale_worktrees[@]}"}"; do info "  $w"; done

if [[ "$DRY_RUN" -eq 1 ]]; then
  info "dry-run only. Re-run with --apply to delete."
  exit 0
fi

for b in "${merged_locals[@]+"${merged_locals[@]}"}"; do
  info "deleting local branch $b"
  git branch -D "$b" || true
done

for w in "${stale_worktrees[@]+"${stale_worktrees[@]}"}"; do
  info "removing worktree $w"
  git worktree remove --force "$w" 2>/dev/null || rm -rf "$w"
done

info "prune_git_stale: done"
