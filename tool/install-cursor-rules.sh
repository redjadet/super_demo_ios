#!/usr/bin/env bash
# Install tracked Cursor rules/MCP from tool/cursor-template/ into a .cursor directory.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TEMPLATE="$ROOT/tool/cursor-template"
DRY_RUN=0

usage() {
  cat <<'EOF'
Usage: ./tool/install-cursor-rules.sh [--dry-run]

Installs Cursor rules and mcp.json from tool/cursor-template/.

Default install directory (parent workspace):
  ../.cursor

Override:
  CURSOR_INSTALL_DIR=/path/to/.cursor ./tool/install-cursor-rules.sh
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help|help)
      usage
      exit 0
      ;;
    -n|--dry-run)
      DRY_RUN=1
      shift
      ;;
    *)
      echo "error: unknown option: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

CURSOR_DIR="${CURSOR_INSTALL_DIR:-$(cd "$ROOT/.." && pwd)/.cursor}"

if [[ ! -d "$TEMPLATE/rules" ]] || [[ ! -f "$TEMPLATE/mcp.json" ]]; then
  echo "error: missing template at $TEMPLATE" >&2
  exit 1
fi

install_file() {
  local src="$1"
  local dest="$2"
  if [[ "$DRY_RUN" -eq 1 ]]; then
    echo "would install: $src -> $dest"
    return 0
  fi
  mkdir -p "$(dirname "$dest")"
  cp -f "$src" "$dest"
  echo "installed: $dest"
}

echo "==> Cursor install target: $CURSOR_DIR"
if [[ "$DRY_RUN" -eq 1 ]]; then
  echo "(dry run)"
fi

for rule in "$TEMPLATE"/rules/*.mdc; do
  [[ -f "$rule" ]] || continue
  install_file "$rule" "$CURSOR_DIR/rules/$(basename "$rule")"
done

install_file "$TEMPLATE/mcp.json" "$CURSOR_DIR/mcp.json"

if [[ "$DRY_RUN" -eq 1 ]]; then
  echo "Dry run complete."
else
  echo "Cursor rules installed. Restart Cursor or reload the window."
fi
