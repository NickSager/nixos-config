---
name: code-review-tuicr
description: Use for code reviews. Deliver findings in chat and tuicr.
metadata:
  hermes:
    tags: [code-review, tuicr, gitlab, human-in-the-loop]
---

# Deliver code reviews through tuicr

Apply this companion contract to every Hermes code-review workflow, including a request that names another review skill. The selected review skill still owns analysis and its verdict. This skill owns delivery.

## Delivery contract

- Return the complete review in chat.
- Mirror the same findings into the matching tuicr session as local drafts.
- Treat this standing preference as an explicit dry-run request to any live-MR review engine. Do not post GitLab comments, replies, coverage notes, approvals, resolutions, or change requests unless the user explicitly asks for direct GitLab writes in the current request.
- Do not modify, weaken, or reimplement the selected review skill's routing, specialist checks, Gatekeeper, or verdict rules.
- Load the `tuicr` skill for session discovery, startup, comment targeting, and error handling.

## Procedure

1. Resolve the review target and engine normally. Tell a live GitLab engine to run in draft or no-post mode before it starts. Delegated reviewers return findings only; they never write to tuicr or GitLab.
2. Find the matching active tuicr session with `tuicr review list`. For local changes, require one active `kind=local` session for the exact checkout and reviewed range. For a live MR, require one active PR session whose forge host, project, and MR IID match the target. A checkout can expose both kinds, so never select by recency alone.
3. If no matching session exists, follow the `tuicr` skill to start one when an interactive pane is available. A live MR session must open the exact MR target. If startup is unavailable, finish the chat review, save the canonical findings JSON in the Hermes scratch directory, and report `TUICR_MIRROR_PENDING` with its absolute path. Never substitute direct GitLab posting.
4. Normalize the final Gatekeeper-cleared or otherwise final findings once. Use an array of objects accepted by `scripts/mirror-findings.py`. Keep each engine-authored comment unchanged, including invisible reviewer markers. Add `username` only to identify its reviewer in the TUI.
5. Present that canonical finding set and verdict in chat. Then run the mirror script against the selected session. Do not generate a second wording for tuicr.
6. Read the session comments back. Report the number added and skipped. A successful review ends only after chat delivery and a verified mirror, or an explicit `TUICR_MIRROR_PENDING` fallback.

## Finding format

```json
[
  {
    "content": "This guard runs after the dereference.",
    "comment_type": "issue",
    "file": "src/cart.ts",
    "line": 42,
    "side": "new",
    "username": "Hermes - Dev"
  },
  {
    "content": "Overall review summary.",
    "comment_type": "note",
    "username": "Hermes - Review team"
  }
]
```

Omit `file` for a review-level comment. Omit `line` for a file-level comment. Add `end_line` for a range. Use `side=old` only for removed lines and `side=new` for added or unchanged lines.

Map blocking and ordinary change requests to `issue`, nits and optional improvements to `suggestion`, questions or summaries to `note`, and exceptional positive findings to `praise`. Use a review-level object only when the review engine produced an overall summary; do not synthesize filler.

Invoke the helper through `terminal`:

```bash
python3 scripts/mirror-findings.py \
  --repo /absolute/repository/path \
  --session SESSION_SLUG \
  --input /absolute/path/findings.json
```

The helper validates the complete payload before writing, skips exact duplicates, invokes `tuicr review add`, and verifies every returned comment through `tuicr review comments`.

## Remote discussion limit

Existing GitLab discussions are read-only in tuicr 0.24. Show relevant thread context in chat, but do not represent a reply as a new top-level draft. If the review calls for a reply, resolution, or reopening, report that action separately as pending. Perform it only when the user explicitly requests direct GitLab writes.

## Verification

- The chat report and tuicr drafts come from the same canonical finding set.
- Every mirrored comment has the intended author, content, target, side, and type when read back.
- No GitLab write occurred unless the current request explicitly authorized it.
- Multiple matching sessions stop for clarification rather than receiving comments arbitrarily.
