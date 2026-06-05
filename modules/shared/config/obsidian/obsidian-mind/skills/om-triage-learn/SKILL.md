---
name: om-triage-learn
description: "Mine closed Goku/WAF triage notes for recurring patterns and resolutions not yet in the mapped runbook, and propose runbook appends as a diff for approval. Never auto-edits. Use periodically (e.g. end of an oncall rotation) to fold field knowledge back into the runbooks."
---

# om-triage-learn — fold triage findings back into the runbooks

The vault is the memory bank. Routine triage notes pile up under `AI/work/triage/`; the
durable knowledge in them should graduate into the runbooks that [[om-triage]] loads, so the
next investigation starts warmer. This skill reads the accumulated notes, finds what recurs,
and proposes runbook edits — it never writes a runbook itself. The operator reviews every
diff. This is the learner step of [[ops-triage-agent-plan]] (Phase 4), mapped onto the
review-everything workflow.

## When to run

Periodically, not per-ticket: end of an oncall rotation, or `/om-triage-learn <category>` to
focus one alarm family. It is read-only over the vault except for the proposal file it writes
under `AI/work/artifacts/ops-triage-agent/`.

## Scope rules

- Never edit a runbook directly. Output is a proposal the operator applies.
- Plain prose in any proposed runbook text — no bold/italic ([[feedback_no_bold_runbook_prose]]).
- Only propose what is supported by cited triage notes; link them. No speculation.
- Prefer adding to an existing runbook section over creating new ones; runbooks are the
  operator's curated source of truth.

## Process

1. Pick the scope: a single `alarm_category` (if given) or all categories.
2. QMD over `AI/work/triage/` for notes in scope; prefer `status: resolved` notes — those
   carry a confirmed outcome. Group by `alarm_category` / `runbook`.
3. For each group, look for signal that recurs across two or more notes and is NOT already in
   the mapped runbook:
   - A confirmed root cause or error chain seen more than once.
   - A diagnostic step or command that proved decisive (e.g. a specific log field, a
     download-then-grep recipe, a metric cross-check).
   - A differential that kept being wrong, or a paired-alarm pattern.
   - A self-resolution signature (how long it took, what it correlated with).
4. Read the mapped runbook under `AI/reference/runbooks/`. Diff what the notes know against
   what the runbook says. Discard anything already documented.
5. For each genuinely new, twice-seen item, draft a concise runbook addition in the runbook's
   own voice and section, each line tied to the triage notes that support it.

## Output

Write a proposal to `AI/work/artifacts/ops-triage-agent/learn-<date>.md` (or
`learn-<category>-<date>.md` for a scoped run). For each proposed change:

- Target runbook + section.
- The proposed text (plain prose, ready to paste).
- Supporting evidence: links to the `[[V...]]` triage notes and the recurrence count.
- A one-line rationale for why it belongs in the runbook now.

Present the proposal in chat and stop. Apply nothing until the operator approves; on approval,
the operator (or a follow-up edit) folds the text into the runbook. Never auto-edit the
runbook, and never post to any ticket from this skill.

## Related

- [[ops-triage-agent]] · [[ops-triage-agent-plan]] — project + full phased design
- [[om-triage]] — the triage skill whose notes this mines
- [[ticket-investigation-workflow]] — the routing table mapping categories → runbooks
- [[feedback_no_bold_runbook_prose]] — plain prose in runbook edits
