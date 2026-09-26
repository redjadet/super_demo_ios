#!/usr/bin/env bash
# Xcode Run Script: embed Flutter frameworks into the app when present.
# Expects flattened dirs from ./tool/prepare_flutter_embed.sh:
#   Flutter/<Config>/iphoneos/*.framework
#   Flutter/<Config>/iphonesimulator/*.framework
# No-op for Mac / when frameworks were not prepared.
set -euo pipefail

# shellcheck disable=SC2154
case "${PLATFORM_NAME:-}" in
  iphoneos|iphonesimulator) ;;
  *)
    echo "note: skip Flutter embed (platform=${PLATFORM_NAME:-unknown})"
    exit 0
    ;;
esac

SRCROOT="${SRCROOT:-}"
CONFIGURATION="${CONFIGURATION:-Debug}"
TARGET_BUILD_DIR="${TARGET_BUILD_DIR:-}"
FRAMEWORKS_FOLDER_PATH="${FRAMEWORKS_FOLDER_PATH:-Frameworks}"

SLICE_DIR="${SRCROOT}/Flutter/${CONFIGURATION}/${PLATFORM_NAME}"
if [[ ! -d "$SLICE_DIR/Flutter.framework" ]]; then
  if [[ "${SUPERDEMO_REQUIRE_FLUTTER_EMBED:-0}" == "1" ]]; then
    echo "error: Flutter frameworks missing at $SLICE_DIR" >&2
    echo "error: run ./tool/prepare_flutter_embed.sh before this iOS build." >&2
    exit 1
  fi
  echo "note: Flutter frameworks not present; building without embed."
  exit 0
fi

DEST="${TARGET_BUILD_DIR}/${FRAMEWORKS_FOLDER_PATH}"
mkdir -p "$DEST"

for name in Flutter App; do
  src="${SLICE_DIR}/${name}.framework"
  if [[ ! -d "$src" ]]; then
    echo "error: missing $src" >&2
    exit 1
  fi
  rm -rf "${DEST}/${name}.framework"
  cp -R "$src" "$DEST/"
  echo "note: embedded ${name}.framework from ${SLICE_DIR}"
done

# Plugin-free modules omit FlutterPluginRegistrant — skip when absent.
if [[ -d "${SLICE_DIR}/FlutterPluginRegistrant.framework" ]]; then
  rm -rf "${DEST}/FlutterPluginRegistrant.framework"
  cp -R "${SLICE_DIR}/FlutterPluginRegistrant.framework" "$DEST/"
  echo "note: embedded FlutterPluginRegistrant.framework from ${SLICE_DIR}"
fi
