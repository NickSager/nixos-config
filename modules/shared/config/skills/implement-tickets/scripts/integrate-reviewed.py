#!/usr/bin/env python3

import argparse
import hashlib
import json
import os
import secrets
import subprocess
import sys
from datetime import UTC, datetime
from pathlib import Path


def git(repository: Path, *arguments: str) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        ["git", "-C", str(repository), *arguments],
        check=False,
        capture_output=True,
        text=True,
    )


def require_git(repository: Path, *arguments: str) -> str:
    result = git(repository, *arguments)
    if result.returncode != 0:
        detail = result.stderr.strip() or result.stdout.strip()
        raise RuntimeError(f"git {' '.join(arguments)} failed: {detail}")
    return result.stdout.strip()


def resolve_commit(repository: Path, revision: str) -> str:
    return require_git(repository, "rev-parse", "--verify", f"{revision}^{{commit}}")


def write_json(path: Path, value: dict) -> None:
    temporary = path.with_suffix(".tmp")
    temporary.write_text(
        json.dumps(value, indent=2, sort_keys=True) + "\n", encoding="utf-8"
    )
    temporary.replace(path)


def target_worktree(repository: Path, target_ref: str) -> Path:
    output = require_git(repository, "worktree", "list", "--porcelain")
    matches: list[Path] = []
    current: Path | None = None
    for line in output.splitlines():
        if line.startswith("worktree "):
            current = Path(line.removeprefix("worktree "))
        elif line == f"branch {target_ref}" and current is not None:
            matches.append(current)
    if len(matches) != 1:
        raise RuntimeError(
            f"{target_ref} must be checked out in exactly one worktree; found {len(matches)}"
        )
    return matches[0]


def clean_for_fast_forward(worktree: Path) -> None:
    status = require_git(worktree, "status", "--porcelain=v1", "--untracked-files=all")
    if status:
        raise RuntimeError(f"target worktree is not clean: {worktree}")


def run_checks(worktree: Path, checks: list[str], evidence_dir: Path) -> list[dict]:
    results = []
    for index, command in enumerate(checks, start=1):
        result = subprocess.run(
            ["/bin/sh", "-lc", command],
            cwd=worktree,
            check=False,
            capture_output=True,
            text=True,
        )
        stdout_path = evidence_dir / f"check-{index:02d}.stdout"
        stderr_path = evidence_dir / f"check-{index:02d}.stderr"
        stdout_path.write_text(result.stdout, encoding="utf-8")
        stderr_path.write_text(result.stderr, encoding="utf-8")
        results.append(
            {
                "command": command,
                "exit_code": result.returncode,
                "stderr": str(stderr_path),
                "stdout": str(stdout_path),
            }
        )
        if result.returncode != 0:
            break
    return results


def make_attempt(
    repository: Path,
    root: Path,
    target: str,
    base: str,
    candidate: str,
    checks: list[str],
    ordinal: int,
) -> tuple[dict, Path]:
    stamp = datetime.now(UTC).strftime("%Y%m%dT%H%M%SZ")
    nonce = secrets.token_hex(4)
    safe_target = target.replace("/", "-")
    attempt_id = f"{stamp}-{os.getpid()}-{ordinal}-{nonce}"
    branch = f"hermes/integrate-{safe_target}-{candidate[:12]}-{attempt_id}"
    worktree = root / attempt_id / "worktree"
    evidence_dir = worktree.parent
    evidence_dir.mkdir(parents=True, exist_ok=False)
    attempt = {
        "base": base,
        "branch": branch,
        "candidate": candidate,
        "checks": [],
        "result": "creating-worktree",
        "worktree": str(worktree),
    }
    write_json(evidence_dir / "evidence.json", attempt)

    add = git(repository, "worktree", "add", "-b", branch, str(worktree), base)
    (evidence_dir / "worktree-add.stdout").write_text(add.stdout, encoding="utf-8")
    (evidence_dir / "worktree-add.stderr").write_text(add.stderr, encoding="utf-8")
    if add.returncode != 0:
        attempt["result"] = "worktree-create-failed"
        write_json(evidence_dir / "evidence.json", attempt)
        return attempt, evidence_dir

    pick = git(worktree, "cherry-pick", candidate)
    (evidence_dir / "cherry-pick.stdout").write_text(pick.stdout, encoding="utf-8")
    (evidence_dir / "cherry-pick.stderr").write_text(pick.stderr, encoding="utf-8")
    if pick.returncode != 0:
        attempt["result"] = "cherry-pick-conflict"
        write_json(evidence_dir / "evidence.json", attempt)
        return attempt, evidence_dir

    attempt["integrated_commit"] = resolve_commit(worktree, "HEAD")
    attempt["checks"] = run_checks(worktree, checks, evidence_dir)
    if any(check["exit_code"] != 0 for check in attempt["checks"]):
        attempt["result"] = "check-failed"
        write_json(evidence_dir / "evidence.json", attempt)
        return attempt, evidence_dir
    if resolve_commit(worktree, "HEAD") != attempt["integrated_commit"]:
        attempt["result"] = "check-mutated-head"
        write_json(evidence_dir / "evidence.json", attempt)
        return attempt, evidence_dir
    try:
        clean_for_fast_forward(worktree)
    except RuntimeError:
        attempt["result"] = "check-mutated-worktree"
        write_json(evidence_dir / "evidence.json", attempt)
        return attempt, evidence_dir
    attempt["result"] = "checks-passed"
    write_json(evidence_dir / "evidence.json", attempt)
    return attempt, evidence_dir


def locked_transaction(args: argparse.Namespace) -> int:
    repository = args.repo.resolve(strict=True)
    common_dir = Path(
        require_git(
            repository,
            "rev-parse",
            "--path-format=absolute",
            "--git-common-dir",
        )
    ).resolve(strict=True)
    held_common_dir = os.environ.get("HERMES_REPO_LOCK_COMMON_DIR")
    if held_common_dir is None or Path(held_common_dir).resolve() != common_dir:
        print("hermes-full-local: repository lock is not held", file=sys.stderr)
        return 76

    transaction: dict | None = None
    transaction_file: Path | None = None
    try:
        require_git(repository, "check-ref-format", "--branch", args.target)
        candidate = resolve_commit(repository, args.candidate)
        reviewed = resolve_commit(repository, args.reviewed)
        if candidate != reviewed:
            raise RuntimeError(
                f"candidate {candidate} does not equal reviewed commit {reviewed}"
            )
        target_ref = f"refs/heads/{args.target}"
        target_path = target_worktree(repository, target_ref)
        identity = hashlib.sha256(os.fsencode(common_dir)).hexdigest()
        transaction_id = "-".join(
            [
                candidate[:12],
                datetime.now(UTC).strftime("%Y%m%dT%H%M%SZ"),
                str(os.getpid()),
                secrets.token_hex(4),
            ]
        )
        root = (
            Path.home()
            / ".cache"
            / "hermes"
            / "full-local-integrations"
            / identity
            / transaction_id
        )
        root.mkdir(parents=True, exist_ok=False)
        transaction = {
            "candidate": candidate,
            "checks": args.check,
            "git_common_dir": str(common_dir),
            "repository": str(repository),
            "result": "running",
            "target": args.target,
            "target_worktree": str(target_path),
            "attempts": [],
        }
        transaction_file = root / "transaction.json"
        write_json(transaction_file, transaction)
        print(root, flush=True)

        for ordinal in range(1, args.max_attempts + 1):
            base = resolve_commit(repository, target_ref)
            attempt, evidence_dir = make_attempt(
                repository, root, args.target, base, candidate, args.check, ordinal
            )
            transaction["attempts"].append(str(evidence_dir / "evidence.json"))
            write_json(transaction_file, transaction)
            if attempt["result"] != "checks-passed":
                transaction["result"] = attempt["result"]
                write_json(transaction_file, transaction)
                raise RuntimeError(
                    f"integration attempt failed; preserved evidence: {evidence_dir}"
                )

            current = resolve_commit(repository, target_ref)
            if current != base:
                attempt["result"] = "target-moved"
                write_json(evidence_dir / "evidence.json", attempt)
                continue
            clean_for_fast_forward(target_path)
            merge = git(
                target_path, "merge", "--ff-only", "--no-edit", attempt["branch"]
            )
            (evidence_dir / "fast-forward.stdout").write_text(
                merge.stdout, encoding="utf-8"
            )
            (evidence_dir / "fast-forward.stderr").write_text(
                merge.stderr, encoding="utf-8"
            )
            if merge.returncode != 0:
                if resolve_commit(repository, target_ref) != base:
                    attempt["result"] = "target-moved-during-fast-forward"
                    transaction["result"] = attempt["result"]
                    write_json(evidence_dir / "evidence.json", attempt)
                    write_json(transaction_file, transaction)
                    raise RuntimeError("target moved while attempting fast-forward")
                attempt["result"] = "fast-forward-failed"
                transaction["result"] = attempt["result"]
                write_json(evidence_dir / "evidence.json", attempt)
                write_json(transaction_file, transaction)
                raise RuntimeError(
                    f"fast-forward failed; preserved evidence: {evidence_dir}"
                )
            attempt["result"] = "integrated"
            attempt["target_after"] = resolve_commit(repository, target_ref)
            write_json(evidence_dir / "evidence.json", attempt)
            transaction["result"] = "integrated"
            transaction["target_after"] = attempt["target_after"]
            write_json(transaction_file, transaction)
            return 0

        transaction["result"] = "target-moved-too-many-times"
        write_json(transaction_file, transaction)
        raise RuntimeError(
            f"target moved before integration {args.max_attempts} times; "
            f"evidence: {root}"
        )
    except (OSError, RuntimeError) as error:
        if (
            transaction is not None
            and transaction_file is not None
            and transaction.get("result") == "running"
        ):
            transaction["result"] = "failed"
            transaction["error"] = str(error)
            write_json(transaction_file, transaction)
        print(f"hermes-full-local: {error}", file=sys.stderr)
        return 1


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--repo", required=True, type=Path)
    parser.add_argument("--candidate", required=True)
    parser.add_argument("--reviewed", required=True)
    parser.add_argument("--target", default="main")
    parser.add_argument("--check", action="append", required=True)
    parser.add_argument("--timeout", type=float, default=3600.0)
    parser.add_argument("--max-attempts", type=int, default=3)
    parser.add_argument("--locked", action="store_true", help=argparse.SUPPRESS)
    args = parser.parse_args()
    if args.timeout < 0:
        parser.error("--timeout must be non-negative")
    if args.max_attempts < 1:
        parser.error("--max-attempts must be positive")
    if args.locked:
        return locked_transaction(args)

    script = Path(__file__).resolve()
    lock_script = script.with_name("with-repo-lock.py")
    repository = args.repo.absolute()
    command = [
        sys.executable,
        str(lock_script),
        "--repo",
        str(repository),
        "--timeout",
        str(args.timeout),
        "--",
        sys.executable,
        str(script),
        "--locked",
        "--repo",
        str(repository),
        "--candidate",
        args.candidate,
        "--reviewed",
        args.reviewed,
        "--target",
        args.target,
        "--max-attempts",
        str(args.max_attempts),
    ]
    for check in args.check:
        command.extend(["--check", check])
    return subprocess.run(command, check=False).returncode


if __name__ == "__main__":
    raise SystemExit(main())
