#!/usr/bin/env python3
"""Run a command with streaming output and terminate its process group on timeout."""

from __future__ import annotations

import argparse
import os
import signal
import subprocess
import sys
import time


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--timeout", type=float, required=True)
    parser.add_argument("command", nargs=argparse.REMAINDER)
    args = parser.parse_args()
    if args.command and args.command[0] == "--":
        args.command = args.command[1:]
    if not args.command:
        parser.error("command is required")
    if args.timeout <= 0:
        parser.error("--timeout must be positive")
    return args


def main() -> int:
    args = parse_args()
    process = subprocess.Popen(args.command, start_new_session=True)
    deadline = time.monotonic() + args.timeout

    while True:
        status = process.poll()
        if status is not None:
            return status
        if time.monotonic() < deadline:
            time.sleep(1)
            continue

        print(
            f"error: command timed out after {int(args.timeout)} seconds: "
            + " ".join(args.command),
            file=sys.stderr,
            flush=True,
        )
        try:
            os.killpg(process.pid, signal.SIGTERM)
        except ProcessLookupError:
            process.wait()
            return 124

        try:
            process.wait(timeout=10)
            return 124
        except subprocess.TimeoutExpired:
            try:
                os.killpg(process.pid, signal.SIGKILL)
            except ProcessLookupError:
                pass
            process.wait()
            return 124


if __name__ == "__main__":
    raise SystemExit(main())
