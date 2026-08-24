---
name: hld-author
description: "Author a high-level design doc / HLD the way the user likes them: ground every claim in the real source, draft at the right altitude in the house style, then run an adversarial multi-lens review and iterate until a team would approve it in a short briefing. Use when asked to write, revise, or review a design doc, HLD, technical proposal, or architecture write-up. Not for one-line answers or code comments."
---

# hld-author — write a design doc a team would approve

Produce a design doc that a team can understand and approve in a short briefing. The value is not a template — every design differs in what sections it needs — it is the *process* that turns a first draft into an approvable one: grounding claims in the actual codebase, writing at the right altitude in the user's house style, and running the design past adversarial reviewers until it holds. This skill exists because that loop, done by hand, took several rounds of the same corrections; it encodes them so the first draft lands close.

Read [[feedback_design_doc_style]] before drafting — it is the authority on style and altitude. This skill is the process around it. Also honor [[feedback_markdown_no_hard_wrap]] and [[feedback_plans_in_obsidian]] (design docs live under `AI/work/artifacts/<project>/`, never `.claude/plans/`).

## When to run

When asked to write, revise, or review an HLD / design doc / technical proposal / architecture write-up. Not for quick answers, code comments, or ticket text (those have their own feedback notes).

## What "good" looks like (the bar)

- Load-bearing only: components and decisions, not justification prose or decoration. Every sentence informs building or approving.
- End-state: describe the final shape; keep phasing/conditionality out unless asked. Prerequisites and gaps get their own section, not woven-in caveats.
- Concrete: name the real packages, files, functions, and metrics in the codebase — not abstractions. This is what grounding in source buys you.
- Gaps surfaced: what is missing, what must be added, what must be faked/spoofed, and the dependency each rests on.
- Every named entity described; every term defined before first use.
- Prose for explanation, bullets for genuine lists of components/options, subsections to group them. No wall of either. No random bold — bold only as consistent structural labels. Single-line paragraphs.

## Process

1. **Gather the real inputs first.** Read the source the design touches — the packages, the sibling code it reuses, the existing patterns it should mirror (alarms, config, tests), and any authoritative external doc (scope spreadsheet, ticket, prior design). Do not design against assumptions; every claim in the doc must trace to something you read. For broad reading, spawn a subagent and keep only the findings.
2. **Find the load-bearing decisions and the seams.** What is the reusable structure (what is data vs code)? Where does it fit or need to change existing structure? What is genuinely missing or must be spoofed? These, not the prose, are the doc.
3. **Draft at altitude** in the house style ([[feedback_design_doc_style]]). Lead with the pillars the reader needs to approve. Give every component/attack/entity a one-line description. Put prerequisites, gaps, and spoofing in their own section.
4. **Adversarial review — do not skip this.** Run the draft past independent reviewers with distinct lenses, verify findings against source, then synthesize a revision list. A Workflow is the clean way to fan these out and adjudicate; a set of parallel subagents also works. Lenses that have earned their place:
   - Maintainability / extensibility — is the reusable seam at the right boundary; does adding the next case really cost only what the doc claims.
   - Simplicity / YAGNI — is anything built for deferred or out-of-scope needs; are two knobs encoding one axis.
   - Correctness vs source — read the files; is every claim about the code true; is it implementable as written.
   - Briefing-readiness — can a reviewer follow it in one read and approve; is anything buried, hand-waved, or contradictory.
   Have the synthesis adjudicate disagreements and rank by (1) does it meet the ask/bar, (2) correctness, (3) simplicity — preferring edits that clarify or cut over edits that add length.
5. **Iterate until approvable.** Apply the revision list, then a confirmation pass (a single reviewer checking the fixes landed and no new contradiction). Repeat until the verdict is "a team would approve this in a short briefing." Stop there; do not gold-plate.

## Notes

- Scope is authoritative-source-driven: if a spreadsheet/ticket defines what is in and out, that governs — parse it exactly (including struck-through / excluded items), and where the examples differ from the authoritative scope, implement the scope.
- Raise design decisions with options and a recommendation, not a silent choice; leave genuinely open questions marked open, not settled.
- Wire the doc into the vault: link it from the project note (## Designs / ## Plan) and the task note, per [[feedback_task_plan_sop]].

## Related

- [[feedback_design_doc_style]] — the style/altitude authority this process serves
- [[feedback_markdown_no_hard_wrap]] · [[feedback_plans_in_obsidian]] · [[feedback_task_plan_sop]] — formatting + placement
- [[feedback_verify_before_asserting]] · [[feedback_canonical_via_code_search]] — grounding claims in source
