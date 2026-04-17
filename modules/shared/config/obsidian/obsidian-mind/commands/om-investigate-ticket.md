# Investigate Ticket

Investigate an operational ticket — pull logs, analyze root cause, draft a ticket comment, and suggest remediation.

## Usage

```
/om-investigate-ticket <TICKET-ID>
```

## Workflow

### 1. Gather Context

1. **Read the ticket** using `TicketingReadActions` — get alarm name, sub-monitors, assignee, existing comments, related tickets.
2. **Check vault** for related knowledge:
   - `AI/reference/` for service-specific notes (e.g., amr-operations, ticket-investigation-workflow)
   - `AI/memory/` for prior investigation patterns
   - `AI/work/` for related incidents or active work
3. **Check the ticket thread** for existing analysis, signals, and context from teammates.
4. **Search for related tickets** with the same alarm or error pattern.

### 2. Identify Service and Log Access

Determine the service type and appropriate log access method:

| Service | Log Access |
|---------|-----------|
| AMR (AWSManagedRules) | `mechanic execute host apollo env download-log` — ~1hr on disk |
| Dataplane (cells/POPs) | `mechanic execute host apollo env grep-log` or Timber |
| Bots services | `run_bots_cloudwatch_queries` (CloudWatch Insights) |

### 3. Pull Logs

1. **Create investigation directory**: `~/workplace/Ops/investigation_<ticket_id>/`
2. **Download logs** from all affected hosts. Name files: `<hostname>_<logname>.<date-hour>`
3. **If on Mac**: SSH to devdesk, create/attach tmux session for the investigation, run mechanic commands there. Files in `~/workplace/Ops/` sync back via unison.
4. **If historical logs needed**: Check Timber access (some accounts lack Mechanic IAM role), try CloudWatch console as fallback.

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

### 6. Save Analysis

Create `investigation_<ticket_id>/analysis_<date>.md` with:
- Root cause summary
- Per-host error counts and timeline
- Key log excerpts showing the pattern
- Deploy correlation assessment
- Remediation path

### 7. Draft Ticket Comment

Save to `investigation_<ticket_id>/ticket_comment.md`. Structure:

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

1. **Print the comment** for user review before posting.
2. **Only post** when the user explicitly says to.
3. **For edits** after posting: update the local file only, let the user edit the ticket manually.

## Guidelines

- Always verify before asserting — check the actual source, don't speculate about provenance.
- Provide differential diagnosis when the evidence supports multiple explanations.
- Reference related tickets and CRs with links.
- Keep the ticket comment focused on what the reader needs: root cause, impact, and what to do next.
- Transfer any reusable service knowledge to `AI/reference/` after investigation.
