---
description: "CR review — works on an existing CR (peer review) OR a project/package (self-review pre-raise). Writes to AI/work/reviews/ and drafts comments onto the CR unpublished. Never publishes."
---

Review code. Two modes, detected from the argument:

1. **Peer review mode** — argument is a CR ID (`CR-269567040`). Clone the CR, draft a review of someone else's change.
2. **Self-review mode** — argument is a project name (`amr-efficacy-canary`), a package path (`src/AWSManagedRulesEfficacyCanaryTests`), or omitted (current directory). Review *my own* recent/unpushed work before I raise a CR — catch issues first.

ARGUMENTS: CR ID, project name, package path, or omitted.

## Mode detection

- Argument matches `CR-\d+` → **peer review mode**
- Argument matches an `AI/work/active/<name>.md` project note → **self-review mode (project)**
- Argument is a directory path (relative or absolute) → **self-review mode (package)**
- No argument → **self-review mode** on the current working directory's nearest package

If ambiguous, ask before proceeding.

---

## Peer review mode (CR-<ID>)

### 1. Check for an existing draft

Read `~/Documents/Notes/AI/work/reviews/CR-<ID>.md`. If it exists, treat it as a prior draft to UPDATE, not overwrite. Note which revision it reviewed.

### 2. Clone the CR

Use `mcp__builder-mcp__CrCheckout` with the CR ID, **always passing `workingDirectory: /Volumes/workplace`**. SOP per [[feedback_cr_review_workflow]] — clone to the workspace, never the OS temp dir. Without `workingDirectory` the tool defaults to `/var/folders/.../cr-checkout-*/`, which the user has rejected — don't rely on the default.

Checkout lands in `/Volumes/workplace/CR-<ID>/`. Record path.

### 3. Fetch CR metadata

Use `mcp__builder-mcp__ReadInternalWebsites` on `https://code.amazon.com/reviews/CR-<ID>`:
- Current revision, author, packages
- Existing approvals (who, which revision)
- Analyzer status (Change Guardian / Coverlay / SAS / Dependency / Security / Inclusive)
- AutoSDE summary
- Description and existing comments (don't duplicate points already raised)

### 4. If a prior draft exists on a newer revision

Diff the revisions in the checkout. Lead with a "rev N → rev M delta" section.
- Trivial delta (rebase/whitespace/comment) → say so, re-affirm prior recommendation
- Substantive delta → review the delta fully

### 5. Analyze the diff

In the checkout:
- `git log --oneline origin/<base>..HEAD`
- `git diff --stat origin/<base>...HEAD`
- `git diff origin/<base>...HEAD -- <path>` per file
- Read source for anything you cite

### 6. Draft the review (see output format below)

### 7. Draft the comments onto the CR

Peer review mode always ends here — this is a step, not an optional extra. Post the findings as **unpublished drafts** on the current revision (`publish=false`), written per the Comment style section below. The user reviews them in CRUX and publishes manually.

- Reply inside an existing analyzer thread when a finding overlaps one (AutoSDE, Coverlay) instead of opening a parallel comment — one thread per issue.
- Inline on the exact `file:line` for line-specific findings; `TOP` for the recommendation and for rolled-up minors.
- Record the post-number-to-topic map in the vault file so the next revision can find them.

Never `publish=true` — see [[feedback_cr_comments_as_drafts]].

### 8. TL;DR to user

```
Draft saved to AI/work/reviews/CR-<ID>.md
Recommendation: <Approve / Approve with Comments / Request Changes> (<key-reason>)
N draft comments on rev <R>, unpublished — review and publish in CRUX
CR: https://code.amazon.com/reviews/CR-<ID>
```

---

## Self-review mode (project / package / cwd)

Goal: **catch your own issues before raising the CR.** Apply peer-review rigor to yourself.

### 1. Resolve scope

- Project name → read `AI/work/active/<name>.md`, extract package list from the "Packages" section, review each
- Package path → review that one package
- No arg → nearest package to cwd (walk up looking for `Config`, `packageInfo`, `package.json`, `Cargo.toml`, `setup.py`)

### 2. Identify the diff to review

For each package:
- `git rev-parse --abbrev-ref HEAD` — current branch
- `git log --oneline @{upstream}..HEAD` — unpushed commits (if upstream tracked)
  - If no upstream: `git log --oneline mainline..HEAD` or the repo's default branch
  - If neither works: review everything since the divergence from `origin/mainline`
- `git diff <base>...HEAD` — the cumulative change as it would appear to a reviewer
- `git status` — any uncommitted work-in-progress (flag but don't review unless explicitly asked)

If the user wants a different scope, they'll say — but default to "what would ship if I raised a CR right now."

### 3. Read the project note (project mode)

Pull the "Source Documents", "Key Decisions", and any open "Divergences from Design Doc" section. The review should flag implementation that contradicts a recorded decision.

### 4. Analyze as a reviewer would

Same focus areas as peer review:
- Correctness vs. stated intent (description in commit messages, related ticket, project-note decisions)
- Error handling, idempotency, failure modes
- Security (IAM scoping, secrets, input validation, injection)
- Observability deltas
- Test coverage for new/changed code paths
- Cross-package consistency — especially [[project_goku_waf_packages]] log field ordering
- Commit hygiene — do commit messages explain *why*? Are related commits logically grouped?
- Dead code, TODOs, commented-out blocks, debug prints

### 5. Run whatever analyzers are cheap locally

If an analyzer is trivially runnable (e.g., `rubocop`, `eslint`, language-native lint) and the project has it configured, note whether the working tree passes. Don't run full builds — that's for the user on devdesk per [[reference_devdesk]].

### 6. Draft the review

Write to `~/Documents/Notes/AI/work/reviews/<project-or-package>-<YYYY-MM-DD>.md`. Example: `amr-efficacy-canary-2026-04-28.md` or `CanaryCDK-2026-04-28.md`.

### 7. TL;DR to user

```
Self-review saved to AI/work/reviews/<name>-<date>.md
Status: <Ready to raise / Address N blockers first / Consider N improvements>
Blockers: <bullet list if any>
Suggested commit message edits: <if any>
```

---

## Output format (both modes)

```markdown
---
date: YYYY-MM-DD
description: <Peer review of CR-<ID> | Self-review of <project/package>> — <brief summary>. <outcome one-liner>.
tags: [code-review, <package/project-relevant tags>, <self-review | peer-review>]
---

# <CR-<ID> Review: <title> | Self-Review: <project/package>>

Links: [[<project-note>]] · [<ticket-url>] · [CR-<ID>](<...>) (peer mode) or [[<branch-name>]] (self mode)

**Recommendation: <Approve / Approve with Comments / Request Changes>** (peer)
OR
**Status: <Ready to raise / Address blockers first / Needs rework>** (self)

<1-2 sentence justification>

---

### What it does (brief)
<2-4 sentence plain-English summary>

### How it does it (detailed)
<per-file walkthrough with file:line references>

---

### Things done well
- <bullet>

### Issues to address
- **<blocker | major | minor>** — <file:line>: <issue>

### Minor observations / nits
#### 1. <title> — `<file:line>`
<body>

### Analyzer feedback
<summary of what passed/failed and whether you concur>

### Cross-package consistency
<single-package vs cross-package notes; flag log-field ordering per [[project_goku_waf_packages]]>

### Commit hygiene (self-review only)
<commit message quality, groupings, anything you'd rewrite before raising>
```

Reference the pattern in `~/Documents/Notes/AI/work/reviews/CR-269809509.md`.

## Comment style (for the comments drafted onto the CR)

The vault review is written for the user. A CR comment is written for the **author** — a different reader, with different context. Rewrite for that reader; do not paste vault prose into CRUX.

**Use the minimum number of words the finding needs.** Most comments are 2-6 short sentences. A one-line finding gets one line. Clarity beats density: several short sentences beat one packed sentence. Drop secondary detail (mechanism internals, edge-case enumeration) unless it changes what the author does next.

Every comment is: finding, where, why it matters, fix. Usually one sentence each, often fewer. If a sentence doesn't change what the author does next, delete it.

**Delete on sight:**

- Preambles and framing — "Worth adding scope before you act on this", "The finding is right but", "Here's what I checked". Open with the finding.
- Restated conclusions — no summarizing the paragraph you just wrote.
- Reproduction method and review-process narration — keep the result, drop the harness, the lens, and the agent count.
- Teaching the author their own codebase or language. Explain a mechanism only when it IS the finding.
- Cheap-fix-versus-real-fix menus. Name the fix you'd take. Mention an alternative only if the choice is genuinely the author's.
- Hedging and softeners — "it may be worth considering", "I'm not claiming". Say it or cut it.

**Keep:** exact counts and file:line, the specific bad outcome, and a not-finding when it stops the author fixing something that isn't broken (one sentence).

**STE (Simplified Technical English).** One idea per sentence, under 20 words. Active voice, present tense, plain words. Use the same word for the same thing every time. Numerals for counts. No semicolon chains, no stacked em-dash asides, no arrow shorthand, no load-bearing parentheticals. Put the fix on its own line, starting "Suggested fix:" followed by a verb.

**Each comment stands alone** — no "see the sibling thread" or "as I noted above". Restate a dependency in one clause and point at the `file:line`. Define a domain term only if the author plausibly doesn't know it, in as few words as possible.

**Credit goes in the TOP comment only**, one or two specifics, not a section. Don't open each inline comment with praise.

No bold or italic in CR comment bodies per [[feedback_no_bold_ticket_comments]]; markdown for structure (lists, code, links) is fine.

## Hard constraints

- **DO draft comments onto the CR; NEVER publish them.** `publish=false` on every `CRAddComment` / `CodeReviewWriteActions` call. Drafting is part of peer review — don't ask first, and don't stop at the vault file. The user reviews the drafts in CRUX and publishes manually. Only `publish=true` if they explicitly say "publish"; "post it" and "go ahead" mean draft. No `Ticketing` writes, no `CRRevisionCreator` comment posts. See [[feedback_cr_comments_as_drafts]].
- **Keep the vault file and the drafts in sync.** When drafts change on the CR, update the vault review in the same pass and record the post-number-to-topic map, so the next revision can find them. Edit existing drafts in place with `update-comment` rather than deleting and reposting — it preserves post numbers and thread parents. See [[feedback_ticket_comment_edits]].
- **NEVER commit or push in self-review mode.** Review only — the user decides what to commit and when. See [[feedback_never_commit_unless_asked]] and [[feedback_never_git_push]].
- **Approval/Status line goes at the TOP** of the review, not the end — see [[feedback_cr_review_workflow]].
- **Vault markdown may use bold** for scannability; strip it from anything posted to CRUX — see [[feedback_no_bold_ticket_comments]].

## Related

- [[feedback_cr_review_workflow]] — SOP for CR reviews
- [[feedback_cr_comments_as_drafts]] — CR comments are always drafts; user publishes
- [[feedback_ticket_comment_edits]] — don't repost; user edits locally
- [[feedback_no_bold_ticket_comments]] — ticket comment text is plain
- [[feedback_never_commit_unless_asked]] — self-review never commits
- [[feedback_never_git_push]] — self-review never pushes
- [[project_goku_waf_packages]] — log field ordering constraint
- [[reference_brazil_workspace]] — workspace structure
- [[reference_devdesk]] — builds run on devdesk, not locally
