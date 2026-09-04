#!/usr/bin/env python3

import argparse
import hashlib
import json
import re
import sys
from pathlib import Path

HEADING = re.compile(r"^#\s+(?P<id>\d+):\s+(?P<title>.+)$", re.MULTILINE)
BLOCKERS = re.compile(r"^\*\*Blocked by:\*\*\s*(?P<value>.+)$", re.MULTILINE)
STATUS = re.compile(r"^\*\*Status:\*\*\s*(?P<value>\S+)\s*$", re.MULTILINE)
CHECKBOX = re.compile(r"^- \[ \] (?P<value>.+)$", re.MULTILINE)
BLOCKER_ID = re.compile(r"(?:^|[;,]\s*)(?P<id>\d+):")


def fail(message: str) -> None:
    raise ValueError(message)


def parse_ticket(path: Path, feature: str, repo_root: Path) -> dict:
    text = path.read_text(encoding="utf-8")
    heading = HEADING.search(text)
    status = STATUS.search(text)
    blockers = BLOCKERS.search(text)
    if heading is None:
        fail(f"{path}: missing '# ID: title' heading")
    if status is None:
        fail(f"{path}: missing status")
    if blockers is None:
        fail(f"{path}: missing blocker declaration")

    ticket_id = heading.group("id")
    if not path.name.startswith(f"{ticket_id}-"):
        fail(f"{path}: filename and heading identifiers differ")
    if status.group("value") != "ready-for-agent":
        fail(f"{path}: status must be ready-for-agent")

    blocker_value = blockers.group("value")
    blocked_by = (
        []
        if blocker_value.startswith("None")
        else [match.group("id") for match in BLOCKER_ID.finditer(blocker_value)]
    )
    if not blocker_value.startswith("None") and not blocked_by:
        fail(f"{path}: blockers must use 'ID: title' entries")

    try:
        source = path.resolve().relative_to(repo_root).as_posix()
    except ValueError:
        fail(f"{path}: ticket is outside repository root")

    acceptance = CHECKBOX.findall(text)
    if not acceptance:
        fail(f"{path}: no acceptance criteria")

    content_fingerprint = hashlib.sha256(text.encode("utf-8")).hexdigest()[:12]
    return {
        "id": ticket_id,
        "title": heading.group("title").strip(),
        "source": source,
        "status": status.group("value"),
        "blocked_by": blocked_by,
        "acceptance": acceptance,
        "content_fingerprint": content_fingerprint,
        "branch": f"agent/{feature}-{ticket_id}",
        "idempotency_key": f"{feature}:{ticket_id}:implementation:{content_fingerprint}",
        "integration_idempotency_prefix": f"{feature}:{ticket_id}:integration:",
    }


def reject_cycles(tickets: list[dict]) -> None:
    parents = {ticket["id"]: ticket["blocked_by"] for ticket in tickets}
    visiting = set()
    visited = set()

    def visit(ticket_id: str) -> None:
        if ticket_id in visiting:
            fail(f"dependency cycle includes {ticket_id}")
        if ticket_id in visited:
            return
        visiting.add(ticket_id)
        for parent in parents[ticket_id]:
            visit(parent)
        visiting.remove(ticket_id)
        visited.add(ticket_id)

    for ticket_id in parents:
        visit(ticket_id)


def build_plan(feature_dir: Path, repo_root: Path) -> dict:
    feature_dir = feature_dir.resolve()
    repo_root = repo_root.resolve()
    spec = feature_dir / "spec.md"
    issues = feature_dir / "issues"
    if not spec.is_file():
        fail(f"missing specification: {spec}")
    if not issues.is_dir():
        fail(f"missing issues directory: {issues}")

    feature = feature_dir.name
    tickets = [
        parse_ticket(path, feature, repo_root)
        for path in sorted(issues.glob("[0-9][0-9]-*.md"))
    ]
    if not tickets:
        fail(f"no numbered tickets in {issues}")

    ids = [ticket["id"] for ticket in tickets]
    if len(ids) != len(set(ids)):
        fail("duplicate ticket identifier")
    known = set(ids)
    for ticket in tickets:
        missing = set(ticket["blocked_by"]) - known
        if missing:
            fail(f"{ticket['id']}: unknown blockers {sorted(missing)}")
    reject_cycles(tickets)

    return {
        "schema_version": 1,
        "program_key": feature,
        "repository": str(repo_root),
        "specification": spec.relative_to(repo_root).as_posix(),
        "tickets": tickets,
    }


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("feature_dir", type=Path)
    parser.add_argument("--repo-root", type=Path, required=True)
    args = parser.parse_args()
    try:
        plan = build_plan(args.feature_dir, args.repo_root)
    except (OSError, ValueError) as error:
        print(f"hermes-ticket-plan: {error}", file=sys.stderr)
        return 2
    json.dump(plan, sys.stdout, indent=2, sort_keys=True)
    sys.stdout.write("\n")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
