---
name: slop-review
description: "Review a prose document that already exists — plan, design doc, wiki, runbook, ticket — and cut the slop: speculation, useless knowledge, unclear jargon, internal inconsistency, unsupported claims, and vault or scratch leaks. Runs an adversarial fresh-reader review, then applies the valid fixes and verifies mechanically. Use when asked to de-slop, tighten, cut, make readable, remove speculation, or prep a doc for sharing. For authoring a design doc from scratch, use hld-author instead."
---

# slop-review — cut the slop from a document

Take a document that already exists and make it read as plain technical English a stranger could act on. The value is the process, not a template: address any inline feedback, re-ground each rewrite in the real source, run the draft past a fresh adversarial reader, then triage and apply. This skill exists because doing it by hand repeated the same moves — an independent reviewer, a triage that separates evidence from slop, and a mechanical verification pass.

This is the review-and-cut counterpart to the `hld-author` skill, which authors a doc from scratch. Both serve the same house style in [[feedback_design_doc_style]]. Honor [[feedback_markdown_no_hard_wrap]].

## When to run

When asked to review for slop, tighten, cut, make readable, remove speculation, or prepare a doc to share. Also run it after a heavy rewrite, before publishing. Not for authoring from scratch (that is `hld-author`), and not for code review.

## What "clean" looks like (the bar)

- Every sentence is a fact or an action. No speculation presented as guidance. Cut hedge words that carry weight: "arguably", "probably", "may", "might", "could" used as the basis for a decision.
- No useless knowledge. Cut trivia, churny counts that anchor nothing (resource counts, association counts), anecdote precision, and any explanation of what you chose not to do.
- Readable to the intended audience. Short sentences. Every obscure term, acronym, or system name is defined at first use. Cutting a glossary does not license cryptic jargon — define the term inline instead.
- Internally consistent. Counts, names, and dates agree everywhere. An enumeration matches its stated count: "2 fact types" followed by a list of 3 is a defect.
- Facts anchored. A load-bearing number carries provenance, or is marked as your own finding. Flag any standalone figure a reader would want a source for.
- Shareable when it will be shared. A doc that leaves the vault holds no [[wikilinks]], no "see my note" pointers, no raw feedback annotations, no TODOs. Keep real internal hyperlinks.
- No broken structure. No cross-reference to a section that was cut, no dangling "see below", no heading with no body.

The distinction that matters most: a count or fact that justifies a decision is evidence, not slop. Do not cut "the standard path has about 140 consumers" only because it lacks a link — anchor it or keep it. Do cut "257 resources after wave 2", which decides nothing.

## Process

1. Establish target and audience. What file, and who reads it? Internal-only, or shared? Shared raises the bar: strip every vault reference. A high-level doc cuts implementation minutiae; a handover keeps it.
2. Address inline feedback first. If the author left `feedback:` lines or comments, resolve each before the slop pass, and delete the annotation once done. Removals are cheap; make them directly.
3. Re-ground every rewrite in source. Never rewrite a section from memory — the doc's own facts may be stale. Read the code, config, or notes, and verify each count, name, and date you touch. Spawn subagents for noisy research and keep only the findings. See [[feedback_verify_before_asserting]].
4. Run an adversarial review. Spawn a fresh reader — a subagent, not yourself — with the 7 lenses below. It reads the whole doc and returns ranked findings, each with the quoted text and a suggested fix. A fresh reader catches the seams the author is blind to.
5. Triage every finding. Apply the valid ones. Reject the rest with a stated reason — usually "evidence, not slop" or "style-conservative". Do not apply a fix that removes a load-bearing fact.
6. Verify mechanically. Grep for the exact things you changed: leftover markers, stale counts, broken cross-references. Run `check.py <file>` from this skill's folder for long sentences, stray emphasis, table integrity, and the wikilink count. A shared doc should read 0 wikilinks. Confirm the consistency greps.
7. Report. State what you cut, what you rewrote from fresh facts, which findings you applied versus rejected, and any honest limit: a figure you could not source, or a convention you broke on instruction.

## The 7 slop lenses (the reviewer's checklist)

1. Speculation — guesses or hedges presented as guidance.
2. Useless knowledge — trivia, over-precise counts, explaining the road not taken.
3. Readability — tangled sentences; jargon or acronyms left unexpanded for the audience.
4. Internal consistency — a number, name, or claim that appears two ways; a count that disagrees with its own list.
5. Unsupported-looking facts — standalone figures or claims with no anchor.
6. Shareability leaks — a [[wikilink]], a "see my note", a raw feedback line, a TODO, a vault-file reference.
7. Structure and seams — orphaned references, dangling "see below", a heading with no body after cuts.

## Notes

- Honor an explicit instruction even when it breaks a standing convention. "Remove all vault references for sharing" overrides the vault's link rule — comply, then flag the conflict so the author can keep a linked working copy.
- Honor an author's correction, but reconcile it with the evidence. If a note says X and the author says Y, and both can be true, phrase it so it is true rather than asserting a change you cannot confirm. See [[feedback_scope_claims_to_evidence_reach]].
- Do not assert an absence from a partial read. Say what you saw. See [[feedback_no_unverified_negatives_in_comments]].
- Do not gold-plate. Stop when it reads clean. A few list-style or procedure sentences over the word limit are fine.

## Related

- [[feedback_design_doc_style]] — the load-bearing-only, end-state house style this review serves
- [[feedback_verify_before_asserting]] — ground every rewrite in source, not memory
- [[feedback_scope_claims_to_evidence_reach]] — phrase a claim so it is true to what you saw
- [[feedback_no_unverified_negatives_in_comments]] — never assert absence from a partial read
- [[feedback_markdown_no_hard_wrap]] — formatting
