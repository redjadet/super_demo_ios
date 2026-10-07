#!/usr/bin/env bash
# tvOS Simulator compile proof. Used by ci-platform-builds.sh.
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

TV_DEST="${CI_TVOS_BUILD_DEST:-generic/platform=tvOS Simulator}"
echo "==> tvOS destination: $TV_DEST"

assert_xcodebuild_matches_developer_dir || exit 1

ci_has_tvos_simulator_destination() {
  "$XCODEBUILD" \
    -project superDemoApp.xcodeproj \
    -scheme superDemoAppTV \
    -showdestinations 2>&1 \
    | grep -q 'platform:tvOS Simulator'
}

if [[ "${CI:-}" == "true" ]] && ! ci_has_tvos_simulator_destination; then
  echo "warning: tvOS Simulator platform unavailable on this GitHub runner; skipping tvOS build" >&2
  exit 0
fi

if [[ -n "${TVOS_DERIVED_DATA_PATH:-}" ]]; then
  TV_DERIVED_DATA_FLAGS=(-derivedDataPath "$TVOS_DERIVED_DATA_PATH")
else
  unset TV_DERIVED_DATA_FLAGS
fi

TV_BUILD_FLAGS=(
  CODE_SIGNING_ALLOWED=NO
  CODE_SIGN_IDENTITY=-
)

run_tv_xcodebuild() {
  if [[ "${CI:-}" == "true" ]]; then
    python3 "$ROOT/tool/run_with_timeout.py" \
      --timeout "${CI_TVOS_XCODEBUILD_TIMEOUT_SECONDS:-900}" \
      -- "$XCODEBUILD" "$@"
  else
    "$XCODEBUILD" "$@"
  fi
}

echo "==> tvOS build ($TV_DEST)"
run_tv_xcodebuild \
  -project superDemoApp.xcodeproj \
  -scheme superDemoAppTV \
  -destination "$TV_DEST" \
  -configuration Debug \
  ${XCODEBUILD_SANDBOX_FLAGS+"${XCODEBUILD_SANDBOX_FLAGS[@]}"} \
  ${XCODEBUILD_WARNINGS_AS_ERRORS_FLAGS+"${XCODEBUILD_WARNINGS_AS_ERRORS_FLAGS[@]}"} \
  ${TV_DERIVED_DATA_FLAGS+"${TV_DERIVED_DATA_FLAGS[@]}"} \
  "${TV_BUILD_FLAGS[@]}" \
  build

echo "tvOS build passed."
