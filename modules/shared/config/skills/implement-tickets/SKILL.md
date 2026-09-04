---
name: implement-tickets
description: Import an approved local Markdown ticket set into Hermes Kanban for isolated implementation, native review, and optional local-only integration. Use only inside Hermes for approved multi-ticket programs.
metadata:
  hermes:
    requires_toolsets: [kanban]
---

# Implement approved tickets through Hermes Kanban

Use this skill only in Hermes. Use a normal session and `/goal` for one task.

## Inputs

Require the feature directory, the credential-domain profile, the Hermes project, and one mode:

- `stack` leaves reviewed commits in their worktrees.
- `full-local` sends reviewed commits through one serial local integration lane.

Reject `full`. Never push, open or merge a pull request, deploy, or modify production.

## Build the graph

1. Run `scripts/plan.py FEATURE_DIR --repo-root REPO_ROOT > PLAN.json` from this skill.
2. Stop if the planner rejects the ticket status, an identifier, a blocker, or a cycle. Do not repair approved requirements while importing them.
3. Select or create one Hermes board for the repository. Keep unrelated repositories on separate boards.
4. Import the graph with `scripts/import.py PLAN.json --profile PROFILE --project PROJECT --check COMMAND [--check COMMAND ...]`. The importer first creates a content-addressed blocked gate, then creates each implementation card with that gate ahead of otherwise-unblocked work, a graph-revision-qualified `idempotency_key` and branch, the selected profile and project, `workspace=worktree`, `goal=true`, `skill=poteto-mode`, complete card body, and blocker parents. It re-reads every card and rejects any mismatch before completing the gate, so no worker can claim a partially imported graph. Re-running the same import must return the existing cards; changing the approved graph or execution contract creates a new isolated graph revision.

When this runs from Telegram, create the program root through the native Kanban tool in that topic, then pass its task ID as `--program-parent`. The importer makes that root a parent of every otherwise-unblocked ticket so Hermes propagates its originating notification subscription through the dependency graph. Only after every card passes post-import verification, the importer completes the program root and releases the ready tickets. Do not add a polling loop.

## Worker contract

Implement only the approved ticket. Work only in the assigned worktree. If the requirements are ambiguous, block the card with the exact question.

Completion requires all acceptance criteria, relevant repository checks, a clean commit, and a review request. The request must include the candidate commit, the checks that ran, the result of each check, and any remaining risk. Do not mark implementation complete directly.

## Review contract

Use Hermes native review dispatch. The reviewer must use fresh context and inspect the approved ticket, the exact candidate commit, its diff, and the check evidence.

Request changes with concrete findings. The implementer must produce a new candidate commit and request review again. A clean verdict must record the reviewed commit, the checks the reviewer ran, the findings, and the remaining risk before the card becomes done.

In `stack` mode, stop after the clean review. Do not update local `main`.

## Full-local integration

After a clean review in `full-local` mode, create one integration card for that exact reviewed commit. Append the reviewed commit to the plan's integration idempotency prefix. Assign every integration card to the same integrator profile.

Make the implementation card a parent of its integration card. Make the previous integration card on this board a parent of the next integration card. This keeps the board readable, but it is not the repository serialization boundary. Separate imports and boards cannot atomically append to one native Hermes dependency chain, and profile routing adds no repository mutex.

Run the complete transaction with this exact shape:

```bash
scripts/integrate-reviewed.py \
  --repo REPOSITORY \
  --candidate CANDIDATE_SHA \
  --reviewed REVIEWED_SHA \
  --target main \
  --check 'EXACT CHECK COMMAND' \
  --check 'ANOTHER EXACT CHECK COMMAND'
```

Pass every repository gate as a separate, repeatable `--check`, in the order it must run. The transaction invokes `scripts/with-repo-lock.py` before reading repository state. The lock derives one identity from Git's canonical common directory, so every worktree, board, import, and Hermes profile for that repository contends on the same kernel-held lock. A timeout blocks the card and leaves `main` unchanged. Process exit releases the lock after crashes, so never delete a lock file to recover it.

The transaction verifies that candidate and reviewed revisions resolve to the same commit, records the current local `main`, creates a unique integration branch and worktree from it without resetting existing state, cherry-picks the candidate, and runs the exact checks. It fast-forwards `main` only through the worktree where `main` is already checked out, and only while that worktree is clean and `main` is unchanged. If `main` moved, it repeats from the new revision and reruns every check.

On a conflict, failed check, dirty target worktree, or failed fast-forward, block the integration card. The transaction leaves `main` unchanged and preserves the integration branch, worktree, command output, and JSON evidence under `~/.cache/hermes/full-local-integrations/`. Never reset, discard work, or continue to the next integration card.

## Ownership

Hermes owns claims, heartbeats, retries, review dispatch, dependency promotion, workspaces, task state, and gateway notifications. This skill owns ticket parsing, stable identities, profile assignment, the worker contract, and the integration policy.
