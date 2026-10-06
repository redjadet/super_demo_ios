#!/usr/bin/env bash
# Boot the CI iPhone simulator in the background (overlap with checkout/setup/build).
# Writes status under ${CI_SIM_BOOT_DIR:-$RUNNER_TEMP/ci-sim-boot}.
#
# Usage (after xcode select / pick):
#   ./tool/ci_simulator_boot_bg.sh
#   # ... other work ...
#   ./tool/ci_simulator_await.sh
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

if [[ "${CI:-}" == "true" ]]; then
  # shellcheck source=select_xcode.sh
  source "$ROOT/tool/select_xcode.sh"
fi

# shellcheck source=resolve_platform_destination.sh
source "$ROOT/tool/resolve_platform_destination.sh"

if [[ -z "${CI_SIMULATOR_DEST:-}" ]]; then
  # shellcheck source=ci_simulator_pick_existing.sh
  source "$ROOT/tool/ci_simulator_pick_existing.sh"
fi

udid="$(destination_udid "${CI_SIMULATOR_DEST}")"
if [[ ! "$udid" =~ ^[0-9A-F-]{36}$ ]]; then
  echo "error: CI_SIMULATOR_DEST has no UDID: ${CI_SIMULATOR_DEST:-}" >&2
  exit 1
fi

boot_dir="${CI_SIM_BOOT_DIR:-${RUNNER_TEMP:-/tmp}/ci-sim-boot}"
mkdir -p "$boot_dir"
pid_file="$boot_dir/boot.pid"
status_file="$boot_dir/boot.status"
log_file="$boot_dir/boot.log"

# Already finished?
if [[ -f "$status_file" ]] && grep -qx 'ready' "$status_file" 2>/dev/null; then
  echo "==> Simulator boot already ready (${udid})"
  exit 0
fi

# Already running?
if [[ -f "$pid_file" ]]; then
  old_pid="$(cat "$pid_file" 2>/dev/null || true)"
  if [[ -n "$old_pid" ]] && kill -0 "$old_pid" 2>/dev/null; then
    echo "==> Simulator boot already running pid=${old_pid} (${udid})"
    exit 0
  fi
fi

echo "starting" >"$status_file"
: >"$log_file"

(
  set +e
  echo "==> Background boot ${udid}" >>"$log_file"
  xcrun simctl boot "$udid" >>"$log_file" 2>&1 || true
  if command -v timeout >/dev/null 2>&1; then
    timeout 240 xcrun simctl bootstatus "$udid" -b >>"$log_file" 2>&1
  else
    python3 "$ROOT/tool/run_with_timeout.py" --timeout 240 -- \
      xcrun simctl bootstatus "$udid" -b >>"$log_file" 2>&1
  fi
  status=$?
  if ((status == 0)); then
    echo "ready" >"$status_file"
  else
    echo "failed:${status}" >"$status_file"
  fi
  exit "$status"
) &
boot_pid=$!
echo "$boot_pid" >"$pid_file"

if [[ -n "${GITHUB_ENV:-}" ]]; then
  {
    echo "CI_SIM_BOOT_DIR=${boot_dir}"
    echo "CI_SIM_BOOT_PID=${boot_pid}"
  } >>"${GITHUB_ENV}"
fi

echo "==> Started background simulator boot pid=${boot_pid} udid=${udid}"
echo "    status=${status_file} log=${log_file}"
