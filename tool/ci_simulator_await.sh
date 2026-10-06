#!/usr/bin/env bash
# Await background simulator boot started by tool/ci_simulator_boot_bg.sh.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

# shellcheck source=resolve_platform_destination.sh
source "$ROOT/tool/resolve_platform_destination.sh"

boot_dir="${CI_SIM_BOOT_DIR:-${RUNNER_TEMP:-/tmp}/ci-sim-boot}"
status_file="$boot_dir/boot.status"
pid_file="$boot_dir/boot.pid"
log_file="$boot_dir/boot.log"
timeout_seconds="${CI_SIM_BOOT_AWAIT_SECONDS:-300}"

udid=""
if [[ -n "${CI_SIMULATOR_DEST:-}" ]]; then
  udid="$(destination_udid "${CI_SIMULATOR_DEST}")"
fi

deadline=$((SECONDS + timeout_seconds))
echo "==> Awaiting simulator boot (timeout ${timeout_seconds}s)"

while ((SECONDS < deadline)); do
  if [[ -f "$status_file" ]]; then
    status="$(tr -d '[:space:]' <"$status_file" || true)"
    case "$status" in
      ready)
        echo "==> Simulator boot ready"
        if [[ -f "$log_file" ]]; then
          tail -n 20 "$log_file" || true
        fi
        exit 0
        ;;
      failed:*)
        echo "error: background simulator boot failed (${status})" >&2
        [[ -f "$log_file" ]] && cat "$log_file" >&2 || true
        exit 1
        ;;
    esac
  fi

  if [[ -n "$udid" ]]; then
    state="$(xcrun simctl list devices -j 2>/dev/null | python3 -c "
import json, sys
udid = sys.argv[1].upper()
data = json.load(sys.stdin)
for devices in data.get('devices', {}).values():
    for d in devices:
        if (d.get('udid') or '').upper() == udid:
            print(d.get('state') or '')
            sys.exit(0)
" "$udid" 2>/dev/null || true)"
    if [[ "$state" == "Booted" ]]; then
      # Confirm bootstatus promptly (usually instant when already Booted).
      if xcrun simctl bootstatus "$udid" -b >/dev/null 2>&1; then
        echo "ready" >"$status_file"
        echo "==> Simulator already Booted (${udid})"
        exit 0
      fi
    fi
  fi

  if [[ -f "$pid_file" ]]; then
    pid="$(cat "$pid_file" 2>/dev/null || true)"
    if [[ -n "$pid" ]] && ! kill -0 "$pid" 2>/dev/null; then
      # Process exited without ready — fall through to failure after status check.
      status="$(tr -d '[:space:]' <"$status_file" 2>/dev/null || true)"
      if [[ "$status" != "ready" ]]; then
        echo "error: boot process exited without ready (status=${status:-missing})" >&2
        [[ -f "$log_file" ]] && cat "$log_file" >&2 || true
        # Last chance: device may still be Booted.
        if [[ -n "$udid" ]] && xcrun simctl bootstatus "$udid" -b >/dev/null 2>&1; then
          echo "ready" >"$status_file"
          echo "==> Simulator boot recovered via bootstatus"
          exit 0
        fi
        exit 1
      fi
    fi
  fi

  sleep 2
done

echo "error: timed out waiting for simulator boot after ${timeout_seconds}s" >&2
[[ -f "$log_file" ]] && tail -n 50 "$log_file" >&2 || true
# Final attempt: direct bootstatus if we have a UDID.
if [[ -n "$udid" ]]; then
  xcrun simctl boot "$udid" 2>/dev/null || true
  if xcrun simctl bootstatus "$udid" -b; then
    echo "ready" >"$status_file"
    echo "==> Simulator boot completed via foreground fallback"
    exit 0
  fi
fi
exit 1
