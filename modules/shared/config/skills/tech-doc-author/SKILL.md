---
name: tech-doc-author
description: "Author operational and component documentation — handovers, runbooks, component docs — in the user's plain technical style: short declarative sentences, every term defined inline, every fact grounded in source and anchored to a path or identifier, 1-2 pages. Use when asked to write a handover, runbook, component doc, onboarding doc, or ops documentation. For a high-level design doc use hld-author; for cutting an existing doc use slop-review."
---

# tech-doc-author — write operational docs in the house style

Write a doc a stranger can operate from. The tone and length rules below are mandatory. The structural moves are a default menu — pick what fits the doc type, don't force the full skeleton.

This is the authoring counterpart to `slop-review` (which cuts an existing doc) and the operational sibling of `hld-author` (which writes design docs). All three serve [[feedback_design_doc_style]]. Honor [[feedback_markdown_no_hard_wrap]].

## When to run

When asked to write a handover, runbook, component doc, onboarding doc, or other operational/technical documentation. Not for design docs or proposals (that is `hld-author`), not for reviewing an existing doc (that is `slop-review`), not for ticket comments.

## Tone rules (mandatory)

- One idea per sentence. Short declarative sentences, active voice, present tense.
- No bold or italic for emphasis ([[feedback_no_bold_runbook_prose]]). Headings, lists, and tables carry the structure.
- No hedging and no marketing. State what the system does, not what it "should" or "aims to" do. If something is planned, say planned and by whom.
- Define every term, tool, service, and acronym inline at first use: "Hydra, the internal scheduled test runner, invokes one series Lambda." Never assume the reader knows an internal codename.
- Anchor every fact. File paths, constants, metric names, and identifiers go in backticks (`api-security-matrix.ts`, `COMPOSITE_TICKETING_SUPPRESSED`). A load-bearing number carries provenance.
- Date-stamp any claim that will go stale: "Wave 2 is held (as of 2026-08-19)."
- Name the failure modes honestly. The most valuable sentence in a doc is often the trap: "a completely dead canary shows all-OK."

## Length rule (mandatory)

1 to 2 pages per doc — roughly 90 lines. If a section outgrows that, split the doc or turn the section into a link to a runbook/wiki page. Do not pad; a 1-page doc that covers the system beats a 4-page doc nobody reads.

## Structural moves (default menu — pick what fits)

- Orientation ladder: what it is → what it consists of → how it works → how to run it → where it stands → what is next. A handover uses all six; a runbook may only need the middle four.
- Top-of-doc pointer links: runbook, dashboard, source-of-truth spreadsheet — before the first heading.
- Component table, 2 columns: name, role. One row per package/service.
- A numbered step-by-step walkthrough of the one core flow ("One canary run, step by step"). One flow only; a second flow is a sign the doc should split.
- A "healthy state" description per environment, so an operator can tell normal from broken without asking anyone.
- A roadmap table with Task and Why columns. The Why cell justifies the task in 1 to 3 sentences; a task nobody can justify gets cut.

## Process

1. Establish doc type, audience, and destination. Shared outside the vault (Bunsho, wiki) means 0 [[wikilinks]] and real hyperlinks only; vault-internal means normal link rules apply.
2. Ground every fact in source before writing it. Read the code, config, or console — never write a claim from memory. Spawn read-only subagents for the noisy checks and keep only the findings. See [[feedback_verify_before_asserting]]. A claim you could not verify gets marked as unverified or cut.
3. Draft under the tone and length rules, using the structural moves that fit.
4. Run `slop-review` on the draft as the verification pass. Do not duplicate its lenses here.
5. Report honest limits: any figure you could not source, any section written from a stale note, any convention broken on instruction.

## Related

- [[feedback_design_doc_style]] — the load-bearing-only house style all three doc skills serve
- [[feedback_verify_before_asserting]] — ground every claim in source, not memory
- [[feedback_terse_ticket_summaries]] — the same short-declarative register, applied to tickets
- [[feedback_no_bold_runbook_prose]] — no emphasis markup in runbook/doc prose
- [[feedback_scope_claims_to_evidence_reach]] — phrase each claim so it is true to what you saw
- [[feedback_markdown_no_hard_wrap]] — one line per paragraph
