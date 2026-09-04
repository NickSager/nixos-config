#!/usr/bin/env python3

import argparse
import fcntl
import hashlib
import json
import os
import subprocess
import sys
import time
from pathlib import Path


def git_common_dir(repository: Path) -> Path:
    result = subprocess.run(
        [
            "git",
            "-C",
            str(repository),
            "rev-parse",
            "--path-format=absolute",
            "--git-common-dir",
        ],
        check=True,
        capture_output=True,
        text=True,
    )
    return Path(result.stdout.strip()).resolve(strict=True)


def lock_path(repository: Path) -> tuple[Path, Path]:
    common_dir = git_common_dir(repository)
    identity = hashlib.sha256(os.fsencode(common_dir)).hexdigest()
    root = Path.home() / ".cache" / "hermes" / "full-local-locks"
    return root / f"{identity}.lock", common_dir


def acquire(handle, timeout: float) -> None:
    deadline = time.monotonic() + timeout
    while True:
        try:
            fcntl.flock(handle, fcntl.LOCK_EX | fcntl.LOCK_NB)
            return
        except BlockingIOError:
            if time.monotonic() >= deadline:
                raise TimeoutError
            time.sleep(min(0.1, max(0.0, deadline - time.monotonic())))


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--repo", required=True, type=Path)
    parser.add_argument("--timeout", type=float, default=3600.0)
    parser.add_argument("--print-path", action="store_true")
    parser.add_argument("command", nargs=argparse.REMAINDER)
    args = parser.parse_args()

    if args.timeout < 0:
        parser.error("--timeout must be non-negative")
    try:
        path, common_dir = lock_path(args.repo)
    except (OSError, subprocess.CalledProcessError) as error:
        print(
            f"hermes-full-local-lock: cannot identify repository: {error}",
            file=sys.stderr,
        )
        return 2
    if args.print_path:
        print(path)
        return 0
    command = args.command
    if command and command[0] == "--":
        command = command[1:]
    if not command:
        parser.error("a command is required")

    path.parent.mkdir(parents=True, exist_ok=True, mode=0o700)
    with path.open("a+", encoding="utf-8") as handle:
        try:
            acquire(handle, args.timeout)
        except TimeoutError:
            print(
                f"hermes-full-local-lock: timed out waiting for {common_dir}",
                file=sys.stderr,
            )
            return 75
        handle.seek(0)
        handle.truncate()
        json.dump(
            {
                "git_common_dir": str(common_dir),
                "pid": os.getpid(),
                "started_unix": int(time.time()),
            },
            handle,
            sort_keys=True,
        )
        handle.write("\n")
        handle.flush()
        os.fsync(handle.fileno())
        child_environment = os.environ.copy()
        child_environment["HERMES_REPO_LOCK_COMMON_DIR"] = str(common_dir)
        try:
            return subprocess.run(
                command,
                cwd=args.repo,
                check=False,
                env=child_environment,
            ).returncode
        except OSError as error:
            print(
                f"hermes-full-local-lock: cannot run command: {error}", file=sys.stderr
            )
            return 126


if __name__ == "__main__":
    raise SystemExit(main())
