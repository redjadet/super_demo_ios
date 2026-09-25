#!/usr/bin/env bash
# Plan or create an isolated AI-agent worktree from a known local Git ref.
# Safe defaults for this repo: branch cursor/<slug>, path .worktrees/<slug>.
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: tool/create_agent_worktree.sh --name <slug> [options]

Plans an isolated worktree by default. Pass --apply to create it.

Options:
  --name <slug>      Task slug used by default branch and path (required).
  --base <git-ref>   Existing local base ref (default: origin/main).
  --branch <branch>  New branch (default: cursor/<slug>).
  --path <path>      New worktree path (default: .worktrees/<slug>).
  --apply            Run git worktree add after all checks pass.
  -h, --help         Show help.

The command never fetches, deletes, reuses, or overwrites refs or paths.
Relative --path values are resolved from the repository root.
EOF
}

name=""
base_ref="origin/main"
branch=""
target_path=""
apply=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --name)
      name="${2:-}"
      [[ -n "$name" ]] || { echo "usage-error|--name requires a value" >&2; exit 2; }
      shift 2
      ;;
    --base)
      base_ref="${2:-}"
      [[ -n "$base_ref" ]] || { echo "usage-error|--base requires a value" >&2; exit 2; }
      shift 2
      ;;
    --branch)
      branch="${2:-}"
      [[ -n "$branch" ]] || { echo "usage-error|--branch requires a value" >&2; exit 2; }
      shift 2
      ;;
    --path)
      target_path="${2:-}"
      [[ -n "$target_path" ]] || { echo "usage-error|--path requires a value" >&2; exit 2; }
      shift 2
      ;;
    --apply)
      apply=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "usage-error|unknown arg: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

if [[ -z "$name" ]]; then
  echo "usage-error|--name is required" >&2
  exit 2
fi
if [[ ! "$name" =~ ^[a-z0-9][a-z0-9_-]*$ ]]; then
  echo "usage-error|invalid name: use lowercase letters, digits, hyphens, or underscores" >&2
  exit 2
fi

repo_root="$(git -C "$(dirname "$0")/.." rev-parse --show-toplevel 2>/dev/null || true)"
if [[ -z "$repo_root" ]]; then
  echo "worktree-error|repository unavailable" >&2
  exit 1
fi

branch="${branch:-cursor/$name}"
target_path="${target_path:-.worktrees/$name}"
if [[ "$target_path" != /* ]]; then
  target_path="$repo_root/$target_path"
fi

if ! git -C "$repo_root" check-ref-format --branch "$branch" >/dev/null 2>&1; then
  echo "usage-error|invalid branch: $branch" >&2
  exit 2
fi
if ! git -C "$repo_root" rev-parse --verify --quiet "$base_ref^{commit}" >/dev/null; then
  echo "worktree-error|base-ref-missing|$base_ref" >&2
  exit 1
fi
if git -C "$repo_root" show-ref --verify --quiet "refs/heads/$branch"; then
  echo "worktree-error|branch-exists|$branch" >&2
  exit 1
fi

target_parent="$(dirname "$target_path")"
worktrees_dir="$repo_root/.worktrees"
# Allow creating the repo-local .worktrees parent (gitignored); other parents must exist.
if [[ ! -d "$target_parent" ]]; then
  if [[ "$target_parent" == "$worktrees_dir" ]]; then
    if (( apply )); then
      mkdir -p "$worktrees_dir"
    fi
  else
    echo "worktree-error|parent-missing|$target_parent" >&2
    exit 1
  fi
fi

if [[ -d "$target_parent" ]]; then
  target_path="$(cd "$target_parent" && pwd -P)/$(basename "$target_path")"
elif (( ! apply )); then
  # Plan mode: parent .worktrees not created yet — still print the intended path.
  target_path="$worktrees_dir/$(basename "$target_path")"
fi

if [[ -e "$target_path" ]]; then
  echo "worktree-error|path-exists|$target_path" >&2
  exit 1
fi
# Allow repo-local .worktrees/<slug> under the primary checkout; still reject
# nesting inside any other linked worktree.
while IFS= read -r existing_path; do
  if [[ "$existing_path" == "$target_path" ]]; then
    echo "worktree-error|path-registered|$target_path" >&2
    exit 1
  fi
  if [[ "$target_path" == "$existing_path"/* ]]; then
    if [[ "$existing_path" == "$repo_root" && "$target_path" == "$worktrees_dir"/* ]]; then
      continue
    fi
    echo "worktree-error|path-inside-worktree|$existing_path" >&2
    exit 1
  fi
done < <(git -C "$repo_root" worktree list --porcelain | sed -n 's/^worktree //p')

echo "worktree|repo|$repo_root"
echo "worktree|base|$base_ref"
echo "worktree|branch|$branch"
echo "worktree|path|$target_path"

if (( ! apply )); then
  echo "worktree|plan|git worktree add -b $branch $target_path $base_ref"
  echo "worktree|hint|pass --apply to create"
  echo "worktree|cd|$target_path"
  exit 0
fi

# Ensure parent exists after mkdir above (default .worktrees path).
if [[ ! -d "$(dirname "$target_path")" ]]; then
  echo "worktree-error|parent-missing|$(dirname "$target_path")" >&2
  exit 1
fi

git -C "$repo_root" worktree add -b "$branch" "$target_path" "$base_ref"
echo "worktree|created|$target_path"
echo "worktree|cd|$target_path"
