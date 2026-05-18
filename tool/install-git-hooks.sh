#!/usr/bin/env bash
# Install tracked git hooks into .git/hooks/ (run once per clone).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SRC="$ROOT/tool/git-hooks/pre-commit"
DEST="$ROOT/.git/hooks/pre-commit"

if [[ ! -d "$ROOT/.git" ]]; then
  echo "error: $ROOT is not a git repository" >&2
  exit 1
fi

if [[ ! -f "$SRC" ]]; then
  echo "error: missing hook source: $SRC" >&2
  exit 1
fi

mkdir -p "$ROOT/.git/hooks"
cp -f "$SRC" "$DEST"
chmod +x "$SRC" "$DEST"
echo "Installed pre-commit hook: $DEST"
echo "Staged .swift commits run ./bin/verify-swift.sh (skip: SKIP_SWIFT_VERIFY=1 or --no-verify)"
