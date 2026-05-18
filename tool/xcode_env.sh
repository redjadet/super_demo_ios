#!/usr/bin/env bash
# Shared Xcode CLI resolution (source, do not execute).
set -euo pipefail

refresh_xcodebuild_from_developer_dir() {
  if [[ -z "${DEVELOPER_DIR:-}" ]]; then
    echo "error: DEVELOPER_DIR is unset (source tool/select_xcode_26_5.sh first)" >&2
    return 1
  fi
  export DEVELOPER_DIR
  export PATH="${DEVELOPER_DIR}/usr/bin:${PATH}"
  XCODEBUILD="${DEVELOPER_DIR}/usr/bin/xcodebuild"
  export XCODEBUILD
  if [[ ! -x "$XCODEBUILD" ]]; then
    echo "error: xcodebuild not found at ${XCODEBUILD}" >&2
    return 1
  fi
}

assert_xcodebuild_matches_developer_dir() {
  refresh_xcodebuild_from_developer_dir || return 1
  local expected="${DEVELOPER_DIR}/usr/bin/xcodebuild"
  if [[ "$XCODEBUILD" != "$expected" ]]; then
    echo "error: XCODEBUILD (${XCODEBUILD}) does not match ${expected}" >&2
    return 1
  fi
  local active_dir
  active_dir="$(xcode-select -p 2>/dev/null || true)"
  if [[ "$active_dir" != "$DEVELOPER_DIR" ]]; then
    if [[ "${CI:-}" == "true" ]]; then
      sudo xcode-select -s "$DEVELOPER_DIR"
    elif ! xcode-select -s "$DEVELOPER_DIR" 2>/dev/null; then
      echo "warning: xcode-select still points at ${active_dir:-unknown}; run: sudo xcode-select -s ${DEVELOPER_DIR}" >&2
    fi
    active_dir="$(xcode-select -p 2>/dev/null || true)"
  fi
  if [[ "$active_dir" != "$DEVELOPER_DIR" ]]; then
    echo "error: xcode-select (${active_dir:-unknown}) does not match DEVELOPER_DIR (${DEVELOPER_DIR})" >&2
    return 1
  fi
  if [[ "${CI:-}" == "true" ]]; then
    local resolved
    resolved="$(command -v xcodebuild || true)"
    if [[ -n "$resolved" && "$resolved" != "$XCODEBUILD" ]]; then
      echo "error: PATH xcodebuild (${resolved}) overrides pinned ${XCODEBUILD}" >&2
      return 1
    fi
  fi
}

# Invoke xcodebuild via xcrun so nested toolchains honor DEVELOPER_DIR (GHA has
# multiple Xcode apps; the usr/bin/xcodebuild shim may exec another app).
run_xcodebuild() {
  assert_xcodebuild_matches_developer_dir || return 1
  /usr/bin/xcrun --developer-dir "$DEVELOPER_DIR" xcodebuild "$@"
}

if [[ -n "${DEVELOPER_DIR:-}" && -x "${DEVELOPER_DIR}/usr/bin/xcodebuild" ]]; then
  refresh_xcodebuild_from_developer_dir
else
  XCODEBUILD="$(command -v xcodebuild || true)"
  export XCODEBUILD
fi

if [[ -z "${XCODEBUILD:-}" || ! -x "$XCODEBUILD" ]]; then
  echo "error: xcodebuild not found (DEVELOPER_DIR=${DEVELOPER_DIR:-unset})" >&2
  exit 1
fi
