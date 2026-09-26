#!/usr/bin/env bash
# watchOS Simulator compile proof (JP-P2-F). Used by ci-platform-builds.sh.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

if [[ "${CI:-}" == "true" ]]; then
  # shellcheck source=../tool/select_xcode.sh
  source "$ROOT/tool/select_xcode.sh"
else
  export PATH="/opt/homebrew/bin:/usr/local/bin:${PATH}"
fi

# shellcheck source=../tool/xcode_env.sh
source "$ROOT/tool/xcode_env.sh"
# shellcheck source=../tool/xcodebuild_sandbox_flags.sh
source "$ROOT/tool/xcodebuild_sandbox_flags.sh"
# shellcheck source=../tool/xcode_warnings_as_errors_flags.sh
source "$ROOT/tool/xcode_warnings_as_errors_flags.sh"

WATCH_DEST="${CI_WATCH_BUILD_DEST:-generic/platform=watchOS Simulator}"
echo "==> watchOS destination: $WATCH_DEST"

assert_xcodebuild_matches_developer_dir || exit 1

ci_has_watch_simulator_destination() {
  "$XCODEBUILD" \
    -project superDemoApp.xcodeproj \
    -scheme superDemoAppWatch \
    -showdestinations 2>&1 \
    | grep -q 'platform:watchOS Simulator'
}

if [[ "${CI:-}" == "true" ]] && ! ci_has_watch_simulator_destination; then
  echo "warning: watchOS Simulator platform unavailable on this GitHub runner; skipping watch build" >&2
  exit 0
fi

if [[ -n "${WATCH_DERIVED_DATA_PATH:-}" ]]; then
  WATCH_DERIVED_DATA_FLAGS=(-derivedDataPath "$WATCH_DERIVED_DATA_PATH")
else
  unset WATCH_DERIVED_DATA_FLAGS
fi

WATCH_BUILD_FLAGS=(
  CODE_SIGNING_ALLOWED=NO
  CODE_SIGN_IDENTITY=-
)

run_watch_xcodebuild() {
  if [[ "${CI:-}" == "true" ]]; then
    python3 "$ROOT/tool/run_with_timeout.py" \
      --timeout "${CI_WATCH_XCODEBUILD_TIMEOUT_SECONDS:-900}" \
      -- "$XCODEBUILD" "$@"
  else
    "$XCODEBUILD" "$@"
  fi
}

echo "==> watchOS build ($WATCH_DEST)"
run_watch_xcodebuild \
  -project superDemoApp.xcodeproj \
  -scheme superDemoAppWatch \
  -destination "$WATCH_DEST" \
  -configuration Debug \
  ${XCODEBUILD_SANDBOX_FLAGS+"${XCODEBUILD_SANDBOX_FLAGS[@]}"} \
  ${XCODEBUILD_WARNINGS_AS_ERRORS_FLAGS+"${XCODEBUILD_WARNINGS_AS_ERRORS_FLAGS[@]}"} \
  ${WATCH_DERIVED_DATA_FLAGS+"${WATCH_DERIVED_DATA_FLAGS[@]}"} \
  "${WATCH_BUILD_FLAGS[@]}" \
  build

echo "watchOS build passed."
