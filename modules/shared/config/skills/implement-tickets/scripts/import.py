#!/usr/bin/env python3

import argparse
import hashlib
import json
import subprocess
import sys
from pathlib import Path

WORKER_CONTRACT = """Implement only this approved ticket in the assigned worktree.
Do not redesign settled requirements. If a requirement is ambiguous, block the card with the exact question.
Completion requires every acceptance criterion, every verification command passing, a clean commit, and a native review request containing the candidate commit, check evidence, and remaining risk.
Never push, open or merge a pull request, deploy, modify production, or update local main."""


def run_json(command: list[str]) -> dict:
    result = subprocess.run(command, check=True, capture_output=True, text=True)
    return json.loads(result.stdout)


def complete_program_parent(args: argparse.Namespace) -> None:
    if not args.program_parent:
        return
    view = run_json([args.hermes, "kanban", "show", "--json", args.program_parent])
    if view["task"]["status"] == "done":
        return
    subprocess.run(
        [
            args.hermes,
            "kanban",
            "complete",
            "--summary",
            "Approved ticket graph imported and verified; dependencies may dispatch.",
            args.program_parent,
        ],
        check=True,
        capture_output=True,
        text=True,
    )


def create_import_gate(plan: dict, args: argparse.Namespace) -> tuple[str, str]:
    identity = {
        "plan": plan,
        "profile": args.profile,
        "project": args.project,
        "program_parent": args.program_parent,
        "checks": args.check,
        "skill": args.skill,
    }
    digest = hashlib.sha256(
        json.dumps(identity, sort_keys=True, separators=(",", ":")).encode()
    ).hexdigest()[:16]
    task = run_json(
        [
            args.hermes,
            "kanban",
            "create",
            "--json",
            "--initial-status",
            "blocked",
            "--idempotency-key",
            f"{plan['program_key']}:import-gate:{digest}",
            "--project",
            args.project,
            f"Import gate: {plan['program_key']}",
        ]
    )
    return task["id"], digest


def release_import_gate(args: argparse.Namespace, gate_id: str) -> None:
    view = run_json([args.hermes, "kanban", "show", "--json", gate_id])
    if view["task"]["status"] == "done":
        return
    subprocess.run(
        [
            args.hermes,
            "kanban",
            "complete",
            "--summary",
            "Approved ticket graph imported and verified; dependencies may dispatch.",
            gate_id,
        ],
        check=True,
        capture_output=True,
        text=True,
    )


def ordered_tickets(tickets: list[dict]) -> list[dict]:
    by_id = {ticket["id"]: ticket for ticket in tickets}
    result = []
    visited = set()

    def visit(ticket_id: str) -> None:
        if ticket_id in visited:
            return
        for parent in by_id[ticket_id]["blocked_by"]:
            visit(parent)
        visited.add(ticket_id)
        result.append(by_id[ticket_id])

    for ticket in tickets:
        visit(ticket["id"])
    return result


def card_body(plan: dict, ticket: dict, checks: list[str]) -> str:
    acceptance = "\n".join(f"- [ ] {item}" for item in ticket["acceptance"])
    verification = "\n".join(f"- `{command}`" for command in checks)
    return f"""Approved ticket: {ticket["source"]}
Approved specification: {plan["specification"]}
Repository: {plan["repository"]}

Acceptance criteria:
{acceptance}

Verification commands (run exactly as written):
{verification}

Worker contract:
{WORKER_CONTRACT}
"""


def verify_task(
    task_view: dict,
    ticket: dict,
    args: argparse.Namespace,
    body: str,
    parents: list[str],
    branch: str,
) -> None:
    task = task_view["task"]
    expected = {
        "assignee": args.profile,
        "workspace_kind": "worktree",
        "branch_name": branch,
        "body": body,
    }
    mismatches = [name for name, value in expected.items() if task.get(name) != value]
    if not task.get("project_id"):
        mismatches.append("project_id")
    if args.skill not in task.get("skills", []):
        mismatches.append("skills")
    if sorted(task_view.get("parents", [])) != sorted(parents):
        mismatches.append("parents")
    goal_mode = any(
        event.get("kind") == "created"
        and event.get("payload", {}).get("goal_mode") is True
        for event in task_view.get("events", [])
    )
    if not goal_mode:
        mismatches.append("goal_mode")
    if mismatches:
        raise ValueError(
            f"{ticket['id']}: existing Kanban card differs in {', '.join(mismatches)}"
        )


def import_plan(plan: dict, args: argparse.Namespace) -> dict:
    ids = {}
    created = []
    gate_id, graph_digest = create_import_gate(plan, args)
    for ticket in ordered_tickets(plan["tickets"]):
        body = card_body(plan, ticket, args.check)
        branch = f"{ticket['branch']}-{graph_digest}"
        parents = [ids[parent] for parent in ticket["blocked_by"]]
        if not parents:
            if args.program_parent:
                parents.append(args.program_parent)
            parents.append(gate_id)
        command = [
            args.hermes,
            "kanban",
            "create",
            "--json",
            "--idempotency-key",
            f"{ticket['idempotency_key']}:graph:{graph_digest}",
            "--assignee",
            args.profile,
            "--project",
            args.project,
            "--workspace",
            "worktree",
            "--branch",
            branch,
            "--goal",
            "--skill",
            args.skill,
            "--body",
            body,
        ]
        for parent in parents:
            command.extend(["--parent", parent])
        command.append(f"{ticket['id']}: {ticket['title']}")
        task = run_json(command)
        ids[ticket["id"]] = task["id"]
        task_view = run_json([args.hermes, "kanban", "show", "--json", task["id"]])
        verify_task(task_view, ticket, args, body, parents, branch)
        created.append({"ticket": ticket["id"], "task": task["id"]})
    complete_program_parent(args)
    release_import_gate(args, gate_id)
    return {
        "program_key": plan["program_key"],
        "import_gate": gate_id,
        "tasks": created,
    }


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("plan", type=Path)
    parser.add_argument("--profile", required=True)
    parser.add_argument("--project", required=True)
    parser.add_argument("--program-parent")
    parser.add_argument("--check", action="append", required=True)
    parser.add_argument("--skill", default="poteto-mode")
    parser.add_argument("--hermes", default="hermes")
    args = parser.parse_args()
    try:
        with args.plan.open(encoding="utf-8") as handle:
            plan = json.load(handle)
        result = import_plan(plan, args)
    except (
        OSError,
        KeyError,
        ValueError,
        json.JSONDecodeError,
        subprocess.CalledProcessError,
    ) as error:
        print(f"hermes-ticket-import: {error}", file=sys.stderr)
        return 2
    json.dump(result, sys.stdout, indent=2, sort_keys=True)
    sys.stdout.write("\n")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
