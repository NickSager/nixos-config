# Code Review

Perform a thorough code review of an Amazon CR (Code Review). Clone the CR, research the packages, understand the changes, and produce a structured review with specific inline comments.

## Usage

```
/om-cr-review <CR-ID>
```

## Workflow

### 1. Clone and Inspect

1. **Clone the CR to a workspace** using `CrCheckout` with the CR ID. Always clone to `/Volumes/workplace/` as the working directory.
2. **Read the CR from code.amazon.com** using `ReadInternalWebsites` to get the description, summary, author, status, revision, analyzer comments, and existing reviewer comments.
3. **Identify packages and files changed** from the CR metadata.

### 2. Understand Context

1. **Check memory** for any prior knowledge of the packages, team, or domain.
2. **Read git history** for each package (`git log --oneline -10`) to understand recent activity and what commits are under review (`git diff HEAD~N..HEAD --stat`).
3. **Read the full diff** for each package (`git diff HEAD~N..HEAD`) — N is the number of commits in the CR.
4. **Read the full content** of all new or significantly modified files. For large existing files, read the changed sections with surrounding context.
5. **Research unfamiliar packages** if needed using `InternalCodeSearch`, `InternalSearch`, or `ReadInternalWebsites` for package repo-info. Update memory with findings.
6. **Read the CR description** carefully — understand the stated purpose, linked tickets, testing claims, and safety justification.

### 3. Evaluate

Assess each of these dimensions:

**Purpose & Appropriateness**
- Do the goals make sense? Is this the right approach?
- Is there precedent in the codebase for this pattern?
- Is this the most parsimonious way to accomplish the goal?

**Correctness**
- Do the changes actually accomplish the stated goals?
- Are there logic errors, off-by-one errors, race conditions?
- Are edge cases handled?
- Do error paths behave correctly?

**Security**
- Any injection risks, buffer overflows, unsafe memory access?
- Are inputs validated at trust boundaries?
- Are secrets or credentials exposed?
- Does FFI code handle null pointers and error codes?

**Safety & Reliability**
- Is the change gated behind feature flags or gradual rollout?
- What happens if the new code fails? Does it degrade gracefully?
- Are there missing null checks, uninitialized variables, or resource leaks?
- Could this cause a crash, hang, or data corruption?

**Testing**
- Are the tests adequate for the scope of changes?
- Are error paths and edge cases tested?
- Are test fixtures appropriate (size, realism)?
- Do tests validate the actual behavior, not just "code runs"?

**Observability**
- Are metrics, logs, and alarms adequate?
- Can operators diagnose issues in production?

**Code Quality**
- Does the code follow existing patterns and conventions?
- Are there leftover TODOs, dead code, or debugging artifacts?
- Is the code readable and maintainable?

**Cross-package Consistency**
- For multi-package CRs, do the changes align across packages?
- Are field orderings, enum values, and config keys consistent?

### 4. Check Analyzer Feedback

Review any automated analyzer comments (AutoSDE, Coverlay, Change Guardian, etc.) from the CR. Cross-reference their findings with your own — confirm, dispute, or add context.

### 5. Write the Review

Structure the output as:

```
## CR-XXXXXX Review: <Title>

**Recommendation: [Approve | Approve with Comments | Request Changes]**

<1-2 sentence justification for the recommendation>

---

### What it does (brief)
<2-3 sentences on what THIS CR specifically changes and why. Describe the delta, not the surrounding system. Focus on what behavior is new or different after these changes land.>

### How it does it (detailed)
<Package-by-package breakdown of changes, with line counts>

---

### Things done well
<Bulleted list of positive observations>

### Issues to address
#### 1. <Issue title> — `file:line`
<Description, why it matters, suggested fix if applicable>

### Minor observations / nits
<Lower-priority items>
```

### 6. Post Comments

After the user reviews the report, post draft comments on the CR using `CRAddComment`:
- Use `location` format: `PackageName:filePath::startLine::endLine:` for inline comments
- Use `revision` matching the current CR revision number
- Set `publish=false` to create drafts the user will review before publishing
- Keep comments concise and actionable
- Reference the specific code and explain *why* something is an issue, not just *what*

### 7. Update Memory

If you researched any packages or domains from scratch, save relevant findings to memory for future reviews.

## Guidelines

- **Verify before asserting** — never say "this will crash" without checking the code path. Read the actual implementation.
- **Respect existing patterns** — if the codebase has an established convention (even an imperfect one), note it rather than blocking the CR for following it.
- **Distinguish severity** — clearly separate blocking issues from nits. Don't hold up a well-gated change for style preferences.
- **Be specific** — reference exact file:line, show code snippets, suggest fixes.
- **Consider the author's context** — read the description, understand the constraints (e.g., "follow-up tasks" means some things are intentionally deferred).
- **Check cross-package alignment** — for multi-package CRs, verify that log formats, field indices, enum values, and config keys are consistent across packages.
