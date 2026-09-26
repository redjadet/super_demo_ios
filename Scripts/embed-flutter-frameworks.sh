#!/usr/bin/env bash
# Xcode Run Script: embed Flutter XCFrameworks into the app when present.
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

FRAMEWORK_DIR="${SRCROOT}/Flutter/${CONFIGURATION}"
if [[ ! -d "$FRAMEWORK_DIR" ]]; then
  if [[ "${SUPERDEMO_REQUIRE_FLUTTER_EMBED:-0}" == "1" ]]; then
    echo "error: Flutter frameworks missing at $FRAMEWORK_DIR" >&2
    echo "error: run ./tool/prepare_flutter_embed.sh before this iOS build." >&2
    exit 1
  fi
  echo "note: Flutter frameworks not present; building without embed."
  exit 0
fi

DEST="${TARGET_BUILD_DIR}/${FRAMEWORKS_FOLDER_PATH}"
mkdir -p "$DEST"

copy_xcframework() {
  local name="$1"
  local xcframework="$FRAMEWORK_DIR/${name}.xcframework"
  if [[ ! -d "$xcframework" ]]; then
    echo "error: missing $xcframework" >&2
    exit 1
  fi

  local slice=""
  case "${PLATFORM_NAME}" in
    iphonesimulator)
      slice="$(find "$xcframework" -maxdepth 1 -type d -name 'ios-*-simulator' | head -1)"
      ;;
    iphoneos)
      slice="$(find "$xcframework" -maxdepth 1 -type d \( -name 'ios-arm64' -o -name 'ios-arm64_*' \) ! -name '*-simulator' | head -1)"
      ;;
  esac
  if [[ -z "$slice" || ! -d "$slice" ]]; then
    echo "error: no matching slice in $xcframework for ${PLATFORM_NAME}" >&2
    ls -la "$xcframework" >&2 || true
    exit 1
  fi

  local framework
  framework="$(find "$slice" -maxdepth 1 -type d -name '*.framework' | head -1)"
  if [[ -z "$framework" ]]; then
    echo "error: no .framework inside $slice" >&2
    exit 1
  fi

  local base
  base="$(basename "$framework")"
  rm -rf "${DEST}/${base}"
  cp -R "$framework" "$DEST/"
  echo "note: embedded ${base} from $(basename "$slice")"
}

copy_xcframework Flutter
copy_xcframework App
copy_xcframework FlutterPluginRegistrant
