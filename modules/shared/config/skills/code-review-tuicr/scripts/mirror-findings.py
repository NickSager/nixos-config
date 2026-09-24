#!/usr/bin/env python3
"""Mirror a canonical review finding set into a tuicr session."""

from __future__ import annotations

import argparse
import json
import subprocess
import sys
from pathlib import Path
from typing import Any

ALLOWED_TYPES = {"none", "issue", "suggestion", "note", "praise"}
ALLOWED_SIDES = {"old", "new"}


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--repo", required=True, help="Absolute checkout path or forge repo selector")
    parser.add_argument("--session", required=True, help="tuicr session slug or session JSON path")
    parser.add_argument("--input", required=True, help="JSON array file, or - for stdin")
    return parser.parse_args()


def load_findings(source: str) -> list[dict[str, Any]]:
    raw = sys.stdin.read() if source == "-" else Path(source).read_text(encoding="utf-8")
    value = json.loads(raw)
    if not isinstance(value, list):
        raise ValueError("input must be a JSON array")
    findings: list[dict[str, Any]] = []
    for index, item in enumerate(value):
        if not isinstance(item, dict):
            raise ValueError(f"finding {index} must be an object")
        findings.append(validate_finding(index, item))
    return findings


def validate_finding(index: int, item: dict[str, Any]) -> dict[str, Any]:
    allowed = {"content", "comment_type", "file", "line", "end_line", "side", "username"}
    unknown = sorted(set(item) - allowed)
    if unknown:
        raise ValueError(f"finding {index} has unknown fields: {', '.join(unknown)}")

    content = item.get("content")
    if not isinstance(content, str) or not content.strip():
        raise ValueError(f"finding {index} requires non-empty content")

    comment_type = item.get("comment_type", "none")
    if comment_type not in ALLOWED_TYPES:
        raise ValueError(f"finding {index} has unsupported comment_type {comment_type!r}")

    side = item.get("side", "new")
    if side not in ALLOWED_SIDES:
        raise ValueError(f"finding {index} has unsupported side {side!r}")

    path = item.get("file")
    line = item.get("line")
    end_line = item.get("end_line")
    if path is not None and (not isinstance(path, str) or not path):
        raise ValueError(f"finding {index} file must be a non-empty string")
    if line is not None and (not isinstance(line, int) or line < 1):
        raise ValueError(f"finding {index} line must be a positive integer")
    if end_line is not None and (not isinstance(end_line, int) or end_line < 1):
        raise ValueError(f"finding {index} end_line must be a positive integer")
    if line is not None and path is None:
        raise ValueError(f"finding {index} line requires file")
    if end_line is not None and line is None:
        raise ValueError(f"finding {index} end_line requires line")
    if end_line is not None and end_line < line:
        raise ValueError(f"finding {index} end_line precedes line")

    username = item.get("username", "Hermes")
    if not isinstance(username, str) or not username.strip():
        raise ValueError(f"finding {index} username must be a non-empty string")

    normalized = dict(item)
    normalized["content"] = content
    normalized["comment_type"] = comment_type
    normalized["side"] = side
    normalized["username"] = username
    return normalized


def run_json(command: list[str]) -> Any:
    result = subprocess.run(command, check=True, text=True, capture_output=True)
    return json.loads(result.stdout)


def comment_key(comment: dict[str, Any]) -> tuple[Any, ...]:
    return (
        comment.get("content"),
        comment.get("path") or comment.get("file"),
        comment.get("start_line") if "start_line" in comment else comment.get("line"),
        comment.get("end_line"),
        comment.get("side", "new"),
        comment.get("comment_type", "none"),
        comment.get("author") or comment.get("username"),
    )


def add_comment(repo: str, session: str, finding: dict[str, Any]) -> None:
    payload = {
        key: value
        for key, value in finding.items()
        if key != "username" and value is not None
    }
    payload["username"] = finding["username"]
    subprocess.run(
        [
            "tuicr",
            "review",
            "add",
            "--repo",
            repo,
            "--session",
            session,
            "--input",
            json.dumps(payload, separators=(",", ":")),
        ],
        check=True,
        text=True,
        capture_output=True,
    )


def main() -> int:
    args = parse_args()
    findings = load_findings(args.input)
    comments_command = [
        "tuicr",
        "review",
        "comments",
        "--repo",
        args.repo,
        "--session",
        args.session,
    ]
    existing = run_json(comments_command)
    if not isinstance(existing, list):
        raise ValueError("tuicr review comments did not return a JSON array")

    existing_keys = {comment_key(comment) for comment in existing}
    added = 0
    skipped = 0
    for finding in findings:
        key = comment_key(finding)
        if key in existing_keys:
            skipped += 1
            continue
        add_comment(args.repo, args.session, finding)
        existing_keys.add(key)
        added += 1

    final_comments = run_json(comments_command)
    final_keys = {comment_key(comment) for comment in final_comments}
    missing = [finding for finding in findings if comment_key(finding) not in final_keys]
    if missing:
        print(json.dumps({"added": added, "skipped": skipped, "missing": missing}), file=sys.stderr)
        return 1

    print(json.dumps({"added": added, "skipped": skipped, "verified": len(findings)}))
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (OSError, ValueError, subprocess.CalledProcessError, json.JSONDecodeError) as error:
        print(f"mirror-findings: {error}", file=sys.stderr)
        raise SystemExit(2)
