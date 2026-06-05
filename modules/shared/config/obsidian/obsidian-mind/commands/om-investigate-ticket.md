---
description: "Investigate an operational ticket — classify, pull logs, analyze root cause, write a vault triage note, draft a ticket comment behind a posting gate"
---

# Investigate Ticket

Investigate an operational ticket — classify and route it, pull logs, analyze root cause,
write a durable triage note to the vault, draft a ticket comment, and suggest remediation.
This is the manual single-ticket command; `/om-triage` (when built) wraps it with queue
polling and routing. See [[ticket-investigation-workflow]] for the full classify→route table.

## Usage

```
/om-investigate-ticket <TICKET-ID>
```

## Workflow

### 0. Classify and Route

Read the ticket title + description and extract: alarm name, region, cell/POP, component,
severity, runbook URL, monitor ID. Map to a category using the routing table in
[[ticket-investigation-workflow]] (Step 0).

Default is always investigate. Take the shortcut path (pend with a tracker link, no
investigation) ONLY when the ticket positively matches an unexpired note in
`AI/reference/known-issues/` or an active LSE in the region. Unknown or low-confidence
classification falls through to a full investigation. Even on the shortcut path, still
write the triage note (step 6) and surface it for review — never pend or post autonomously.

### 1. Gather Context

1. **Read the ticket** using `TicketingReadActions` — get alarm name, sub-monitors, assignee, existing comments, related tickets.
2. **Check vault** for related knowledge:
   - `AI/reference/` and `AI/reference/runbooks/` for the mapped runbook + service notes
   - `AI/work/triage/` and `AI/work/incidents/` for prior investigations (use QMD search)
   - `AI/memory/` for prior investigation patterns
3. **Check the ticket thread** for existing analysis, signals, and context from teammates.
4. **Search for related tickets** with the same alarm or error pattern.

### 2. Identify Service and Log Access

Determine the service type and appropriate log access method:

| Service | Log Access |
|---------|-----------|
| AMR (AWSManagedRules) | `mechanic execute host apollo env download-log` — ~1hr on disk |
| Dataplane (cells/POPs) | `mechanic execute host apollo env grep-log` or Timber |
| Bots services | `run_bots_cloudwatch_queries` (CloudWatch Insights) |

Log strategy by ticket age: < ~1hr → live logs via Mechanic; older → Timber (live rotated).

### 3. Pull Logs

1. **Create scratch directory**: `~/workplace/Ops/investigation_<ticket_id>/` (raw logs only).
2. **Download logs** from all affected hosts. Name files: `<hostname>_<logname>.<date-hour>`.
3. **If on Mac**: SSH to devdesk, create/attach tmux session 0 for the investigation, run mechanic commands there. Files in `~/workplace/Ops/` sync back via unison. Never bare `ssh devdesk "<cmd>"` — route through tmux session 0.
4. **If historical logs needed**: prefer download-then-grep locally for multi-host fan-out; don't use `grep-log --modified-after` (it hangs). Check Timber access (some accounts lack the Mechanic IAM role); CloudWatch console is the fallback.

### 4. Analyze

For each log file:
- Count error types and frequency per host per hour
- Identify the error chain (what triggers what — look for WARN→ERROR sequences)
- Check for deploy correlation (compare timing with VFI/deploy events mentioned in ticket)
- Compare across hosts — is every host affected equally?
- Identify which workers/components are most affected and why
- Assess customer impact (self-recovering? data loss? latency?)

When uncertain about mechanism, provide differential diagnosis rather than asserting a single cause.

### 5. Check for Existing Fixes

- Search for related CRs on code.amazon.com using `ReadInternalWebsites`
- Check Asana for existing tracking tasks
- If a CR exists, read the diff and reviewer comments to assess whether it fully addresses the issue

### 6. Write the Vault Triage Note

Write the durable, searchable record to `AI/work/triage/<TICKET-ID>.md`. This replaces the
old ad-hoc `analysis_<date>.md`; raw logs stay in the Ops scratch dir from step 3.

Frontmatter:

```yaml
---
date: "<YYYY-MM-DD>"
description: "<~150 char one-liner: alarm, region, probable root cause>"
ticket: <TICKET-ID>
alarm_category: <category from routing table>
region: <region>
component: <component>
runbook: <runbook note name, e.g. runbook-failopen>
status: drafted          # drafted | posted | resolved | promoted
posted: false            # autonomy-gate audit field — flip to true only when posted
tags: [triage, ops, goku, <category>]
aliases: [<TICKET-ID>]
---
```

Body sections:
- Classification — category, region, cell/POP, component, runbook, log strategy
- Investigation — per-host error counts and timeline, key log excerpts with timestamps
- Differential Diagnosis — ranked possible causes when evidence supports more than one
- Customer Impact — self-recovering? data loss? latency?
- Drafted Comment — the plain-text comment block from step 7 (verbatim)
- Related — `[[<runbook>]]`, ticket link, prior `[[<TICKET>]]` triage notes, related CRs

Link the note: at minimum the mapped runbook and any related triage/incident notes
(orphan notes are a bug). Promote high-signal investigations to `AI/work/incidents/` via
`/om-incident-capture`.

### 7. Draft Ticket Comment

Include the comment verbatim inside the triage note's Drafted Comment section. Structure:

```
## Investigation — <ticket_id>

Alarm: <alarm name>
Sub-monitor: <specific monitor>
Related: <related tickets>

### Root Cause: <one-line summary>

<Detailed explanation of the error chain>
<Key log excerpts with timestamps>
<Error frequency data>

### Deploy Correlation

<Assessment — new issue or latent bug?>

### Customer Impact

<Self-recovering? Data loss? Latency?>

### Remediation

<Existing CRs and their coverage>
<What still needs to be fixed>
<Links to existing Asana/SIM tracking>
<Additional investigations recommended>
```

Formatting rules:
- No bold or italic emphasis — plain text only
- Code formatting (backticks, code blocks) and headers are fine
- When uncertain about root cause mechanism, list possible causes rather than asserting one

### 8. Review and Post

1. **Print the comment** for user review before posting. Review-only is the default.
2. **Only post** when the user explicitly says to. On post, set `posted: true` and `status: posted` in the note frontmatter.
3. **For edits** after posting: update the local note only, let the user edit the ticket manually.

## Guidelines

- Always verify before asserting — check the actual source, don't speculate about provenance.
- Provide differential diagnosis when the evidence supports multiple explanations.
- Reference related tickets and CRs with links.
- Keep the ticket comment focused on what the reader needs: root cause, impact, and what to do next.
- Transfer any reusable service knowledge to `AI/reference/` after investigation.
