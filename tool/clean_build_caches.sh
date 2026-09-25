#!/usr/bin/env bash
# Delete regenerable Xcode / SwiftPM build caches for this repo (disk reclaim).
#
# Safe targets only (rebuildable):
#   - DerivedData folders matching this project name
#   - repo .build/, build/, DerivedData/ if present
#   - SwiftPM scratch under ~/Library/Caches/org.swift.swiftpm (optional --spm-cache)
#
# Never deletes: source, secrets, .git, signing assets, xcuserdata under project
# (unless --derived-data only).
#
# Safety: dry-run by default. Pass --apply to delete.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

DRY_RUN=1
ASSUME_YES=0
DO_SPM=0
PROJECT_NAME="superDemoApp"

usage() {
  cat <<'EOF'
tool/clean_build_caches.sh — reclaim disk (Xcode/Swift regenerable caches).

Deletes when present (preview by default):
  - ~/Library/Developer/Xcode/DerivedData/<Project>-*
  - repo .build/, build/, DerivedData/
  - optional: ~/Library/Caches/org.swift.swiftpm (--spm-cache)

Options:
  --dry-run       List only (default)
  --apply         Delete listed paths
  --yes, -y       Skip confirmation with --apply
  --spm-cache     Also clear user SwiftPM download cache
  -h, --help      Help

Examples:
  bash tool/clean_build_caches.sh
  ./bin/clean-build-caches --apply --yes
EOF
}

die() { echo "error: $*" >&2; exit 2; }

log() { printf '%s\n' "$*"; }

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run) DRY_RUN=1; shift ;;
    --apply) DRY_RUN=0; shift ;;
    --yes|-y) ASSUME_YES=1; shift ;;
    --spm-cache) DO_SPM=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) die "unknown option: $1" ;;
  esac
done

candidates=()

derived_root="${HOME}/Library/Developer/Xcode/DerivedData"
if [[ -d "$derived_root" ]]; then
  while IFS= read -r -d '' path; do
    candidates+=("$path")
  done < <(find "$derived_root" -maxdepth 1 -type d -name "${PROJECT_NAME}-*" -print0 2>/dev/null || true)
fi

for rel in .build build DerivedData; do
  if [[ -e "$ROOT/$rel" ]]; then
    candidates+=("$ROOT/$rel")
  fi
done

if [[ "$DO_SPM" -eq 1 ]]; then
  spm="${HOME}/Library/Caches/org.swift.swiftpm"
  [[ -d "$spm" ]] && candidates+=("$spm")
fi

if [[ ${#candidates[@]} -eq 0 ]]; then
  log "clean_build_caches: nothing to remove"
  exit 0
fi

log "clean_build_caches: targets (${#candidates[@]})"
for path in "${candidates[@]}"; do
  if command -v du >/dev/null 2>&1; then
    size="$(du -sh "$path" 2>/dev/null | awk '{print $1}' || echo '?')"
    log "  $size  $path"
  else
    log "  $path"
  fi
done

if [[ "$DRY_RUN" -eq 1 ]]; then
  log "dry-run only. Re-run with --apply to delete."
  exit 0
fi

if [[ "$ASSUME_YES" -ne 1 ]]; then
  read -r -p "Delete listed paths? [y/N] " ans
  [[ "$ans" == "y" || "$ans" == "Y" ]] || die "aborted"
fi

for path in "${candidates[@]}"; do
  log "removing $path"
  rm -rf "$path"
done

log "clean_build_caches: done"
