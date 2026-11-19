#!/usr/bin/env python3
"""Build PLAN.json for import.py from one of two ticket sources.

Local mode: a feature directory with spec.md and issues/NN-*.md written by to-tickets.
Jira mode: a JSON export of the epic's child issues, fetched through the Atlassian MCP
and saved to a file, plus the key of the issue that holds the spec. Scripts have no
Jira credentials on their own, so the agent does the fetch and the planner does the
validation. Both modes produce the same plan shape, so import.py does not care.
"""

import argparse
import hashlib
import json
import re
import sys
from pathlib import Path
from typing import NoReturn

HEADING = re.compile(r"^#\s+(?P<id>\d+):\s+(?P<title>.+)$", re.MULTILINE)
BLOCKERS = re.compile(r"^\*\*Blocked by:\*\*\s*(?P<value>.+)$", re.MULTILINE)
STATUS = re.compile(r"^\*\*Status:\*\*\s*(?P<value>\S+)\s*$", re.MULTILINE)
CHECKBOX = re.compile(r"^- \[ \] (?P<value>.+)$", re.MULTILINE)
BLOCKER_ID = re.compile(r"(?:^|[;,]\s*)(?P<id>\d+):")

# Jira renders "[ ]" in markdown as "\[ \]"; accept either, with "*" or "-" bullets.
JIRA_CHECKBOX = re.compile(r"^\s*[*-]\s*\\?\[ \\?\]\s*(?P<value>.+?)\s*$", re.MULTILINE)
READY_LABEL = "ready-for-agent"
BLOCKED_BY_LINK = "is blocked by"
DONE_CATEGORY = "Done"


def fail(message: str) -> NoReturn:
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
    if status.group("value") != READY_LABEL:
        fail(f"{path}: status must be {READY_LABEL}")

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
    return ticket_record(
        feature=feature,
        ticket_id=ticket_id,
        title=heading.group("title").strip(),
        source=source,
        blocked_by=blocked_by,
        acceptance=acceptance,
        content_fingerprint=content_fingerprint,
        branch=f"agent/{feature}-{ticket_id}",
    )


def ticket_record(**fields) -> dict:
    feature = fields.pop("feature")
    ticket_id = fields["ticket_id"]
    return {
        "id": ticket_id,
        "title": fields["title"],
        "source": fields["source"],
        "status": READY_LABEL,
        "blocked_by": fields["blocked_by"],
        "acceptance": fields["acceptance"],
        "content_fingerprint": fields["content_fingerprint"],
        "branch": fields["branch"],
        "idempotency_key": f"{feature}:{ticket_id}:implementation:{fields['content_fingerprint']}",
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


def validate_graph(tickets: list[dict]) -> None:
    ids = [ticket["id"] for ticket in tickets]
    if len(ids) != len(set(ids)):
        fail("duplicate ticket identifier")
    known = set(ids)
    for ticket in tickets:
        missing = set(ticket["blocked_by"]) - known
        if missing:
            fail(f"{ticket['id']}: unknown blockers {sorted(missing)}")
    reject_cycles(tickets)


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
    validate_graph(tickets)

    return {
        "schema_version": 1,
        "program_key": feature,
        "repository": str(repo_root),
        "specification": spec.relative_to(repo_root).as_posix(),
        "tickets": tickets,
    }


# --- Jira export ---------------------------------------------------------------


def jira_issues(export: object) -> list[dict]:
    """Accept the MCP result shapes as saved: a search (data.issues), one issue (data
    with key), a list of either, or a bare list of issues."""
    if isinstance(export, dict) and "result" in export and isinstance(export["result"], str):
        return jira_issues(json.loads(export["result"]))
    if isinstance(export, dict) and "data" in export:
        return jira_issues(export["data"])
    if isinstance(export, dict) and "issues" in export:
        return list(export["issues"])
    if isinstance(export, dict) and "key" in export and "fields" in export:
        return [export]
    if isinstance(export, list):
        return [issue for item in export for issue in jira_issues(item)]
    fail("jira export: unrecognised shape; expected MCP search or issue results")


def jira_slug(summary: str) -> str:
    words = re.sub(r"[^a-z0-9]+", "-", summary.lower()).strip("-").split("-")
    return "-".join(words[:6])


def parse_jira_ticket(issue: dict, feature: str, site: str, external: set[str]) -> dict:
    key = issue.get("key")
    fields = issue.get("fields") or {}
    if not key:
        fail("jira export: issue without a key")
    summary = (fields.get("summary") or "").strip()
    description = fields.get("description") or ""
    labels = fields.get("labels") or []
    category = ((fields.get("status") or {}).get("statusCategory") or {}).get("name")
    if READY_LABEL not in labels:
        fail(f"{key}: missing label {READY_LABEL}")
    if category == DONE_CATEGORY:
        fail(f"{key}: already done")
    if "issuelinks" not in fields:
        fail(f"{key}: export has no issuelinks field; fetch with issuelinks included")

    blocked_by = [
        link["inwardIssue"]["key"]
        for link in fields["issuelinks"] or []
        if (link.get("type") or {}).get("inward") == BLOCKED_BY_LINK
        and link.get("inwardIssue")
        and link["inwardIssue"]["key"] not in external
    ]
    acceptance = JIRA_CHECKBOX.findall(description)
    if not acceptance:
        fail(f"{key}: no acceptance criteria (unchecked checkboxes) in the description")

    content_fingerprint = hashlib.sha256(
        (summary + "\n" + description).encode("utf-8")
    ).hexdigest()[:12]
    return ticket_record(
        feature=feature,
        ticket_id=key,
        title=summary,
        source=f"https://{site}/browse/{key}",
        blocked_by=blocked_by,
        acceptance=acceptance,
        content_fingerprint=content_fingerprint,
        branch=f"feat/{key}-{jira_slug(summary)}",
    )


def build_jira_plan(
    export_path: Path,
    spec_key: str,
    repo_root: Path,
    program: str | None,
    site: str,
    external: set[str],
) -> dict:
    repo_root = repo_root.resolve()
    with export_path.open(encoding="utf-8") as handle:
        issues = jira_issues(json.load(handle))
    by_key = {issue.get("key"): issue for issue in issues}
    if spec_key not in by_key:
        fail(f"spec issue {spec_key} is not in the export")
    if external & set(by_key):
        fail(f"external blockers must not be in the export: {sorted(external & set(by_key))}")

    feature = program or spec_key.lower()
    tickets = [
        parse_jira_ticket(issue, feature, site, external)
        for key, issue in sorted(by_key.items())
        if key != spec_key
    ]
    if not tickets:
        fail("jira export holds no tickets besides the spec")
    validate_graph(tickets)

    return {
        "schema_version": 1,
        "program_key": feature,
        "repository": str(repo_root),
        "specification": f"https://{site}/browse/{spec_key}",
        "external_blockers": sorted(external),
        "tickets": tickets,
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("feature_dir", type=Path, nargs="?", help="local mode: to-tickets feature dir")
    parser.add_argument("--repo-root", type=Path, required=True)
    parser.add_argument("--jira-export", type=Path, help="Jira mode: saved MCP result JSON")
    parser.add_argument("--spec", help="Jira mode: key of the issue holding the spec")
    parser.add_argument("--program", help="Jira mode: program key (default: spec key, lowercase)")
    parser.add_argument("--site", default="becn.atlassian.net")
    parser.add_argument(
        "--external-blocker",
        action="append",
        default=[],
        metavar="KEY",
        help="Jira mode: a blocker outside this program that is satisfied another way "
        "(for example by stacking the branch on it); dropped from the graph, recorded in the plan",
    )
    args = parser.parse_args()
    try:
        if args.jira_export:
            if not args.spec:
                fail("--jira-export requires --spec")
            if args.feature_dir:
                fail("choose one source: feature_dir or --jira-export")
            plan = build_jira_plan(
                args.jira_export,
                args.spec,
                args.repo_root,
                args.program,
                args.site,
                set(args.external_blocker),
            )
        elif args.feature_dir:
            plan = build_plan(args.feature_dir, args.repo_root)
        else:
            fail("give a feature_dir (local) or --jira-export with --spec (Jira)")
    except (OSError, ValueError, json.JSONDecodeError, KeyError, TypeError) as error:
        print(f"hermes-ticket-plan: {error}", file=sys.stderr)
        return 2
    json.dump(plan, sys.stdout, indent=2, sort_keys=True)
    sys.stdout.write("\n")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
