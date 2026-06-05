---
name: om-triage
description: "Orchestrate Goku/WAF Dataplane oncall ticket triage — classify, route to a runbook-backed specialist or direct handler, write a vault triage note, and draft a ticket comment behind a posting gate. Use when triaging a SEV2 ticket or polling the oncall queue."
---

# om-triage — Goku/WAF Dataplane Ticket Triage

Classify → route → investigate → write a durable triage note → draft a comment behind a
single posting gate. This is the orchestration layer over [[ticket-investigation-workflow]];
`/om-investigate-ticket` remains the manual single-ticket escape hatch this skill calls into
when a full dive is needed.

Rule of thumb: prose and orchestration live in the vault; code and enforcement live in the
`waf-dp-triage` MCP server (MattsHackyStuffDotCom Brazil package). When that server is
connected, prefer its tools; otherwise fall back to the inline prose path below.

## Enforcement boundaries (read first)

These are code, not suggestions — the `waf-dp-triage` server enforces them:

- `mhs_command` returns a validated run plan; it never executes. Read-only commands
  (`get_`, `find_`, `is_`, `mechanic_`, `per_dataplane_*`) are planned; destructive prefixes
  (`bounce_`, `set_`, `delete_`, `terminate_`, `clear_cores_`, `disable_`, `enable_`,
  `down_svc_`, `automitigate_`) are hard-blocked and cannot be planned.
- `post_comment` routes through the posting gate. Review-only by default — it returns a
  drafted body for a human to approve and posts nothing. Auto-post is per-category and off
  until formats settle.
- Host execution still goes through devdesk tmux session 0 today (never bare
  `ssh devdesk "<cmd>"`); the server plans the command, the operator runs it on the
  permitted path. See [[feedback_devdesk_tmux_workflow]].

## Standing rules carried into every triage

- tmux session 0 for all devdesk commands; never bare ssh ([[feedback_devdesk_tmux_workflow]]).
- Never bounce/rm/terminate without asking ([[feedback_never_rm_without_asking]]).
- Show the verbatim comment and get explicit approval before posting ([[feedback_show_before_posting]]).
- Plain text in comments — no bold/italic; tables/links/code are fine ([[feedback_no_bold_ticket_comments]]).
- Verify before asserting; differential diagnosis when uncertain ([[feedback_verify_before_asserting]], [[feedback_differential_diagnosis]]).

## Modes

```
/om-triage <TICKET-ID>      # triage one ticket
/om-triage --poll           # fetch the SEV2 queue, triage each new ticket (Phase 3)
```

## Flow

### 1. Classify

If the `waf-dp-triage` server is connected, call `classify_ticket(title, description)` and
use the returned `{category, region, site, component, runbook, specialist, default_action,
confidence}`. Otherwise classify inline using the Step 0 routing table in
[[ticket-investigation-workflow]].

### 2. Route

- Positive match to an unexpired note in `AI/reference/known-issues/` or an active LSE →
  shortcut (pend + tracker link). Still write the triage note and surface for review; never
  pend or post autonomously.
- A category that maps to a specialist (see the table below) → dispatch that agent.
- Unknown / low confidence → full investigation via `/om-investigate-ticket` (fail-safe).

### 3. Load context

Before dispatching, gather prior knowledge so the specialist starts warm:

- QMD over `AI/work/triage/` and `AI/work/incidents/` for prior investigations of the same
  alarm/region.
- The mapped runbook under `AI/reference/runbooks/`.
- Related tickets with the same alarm or deduplicator.

### 4. Dispatch the specialist

Route to the runbook-backed agent. Each loads its runbook and returns a structured finding
(per-host counts, log excerpts with timestamps, differential, customer impact).

| Category | Specialist | Runbook(s) |
|----------|-----------|-----------|
| FailOpen | `triage-failopen` | [[runbook-failopen]] |
| FailClosed | `triage-failclosed` | [[runbook-failclosed]] |
| Cores / 5XX / WHU / LMDB / BVLU / GeoDB / NginxConfigUpdater | `triage-host` | [[runbook-cores-5xx]], [[runbook-whu]], [[runbook-lmdb]], [[runbook-bvlu]], [[runbook-geodb]], [[runbook-nginx-config-updater]], [[runbook-instance-mgmt]] |
| Scaling / capacity / CFInstanceManager | `triage-deploy` | [[runbook-scaling]], [[runbook-instance-mgmt]] |
| RBR / entity-not-found | `triage-rbr` | [[runbook-rbr-customer-ticket]], [[sop-rbr-allowed-requests]] |
| Customer logs / log publishing / Bots / AMR efficacy | `triage-log-diver` | [[runbook-dropping-logs]], [[runbook-bots]], [[runbook-amr-efficacy-canary]] |
| Backbone congestion | `triage-metric-diver` | [[runbook-backbone-congestion]], [[runbook-dashboards]] |
| Unknown / low confidence | full dive via `/om-investigate-ticket` | [[ticket-investigation-workflow]] |

### 5. Write the vault triage note

Write `AI/work/triage/<TICKET-ID>.md` with the schema in [[ticket-investigation-workflow]]
(frontmatter mirrors the incident-note shape: `ticket`, `alarm_category`, `region`,
`component`, `runbook`, `status`, `posted`). Body: Classification · Investigation ·
Differential Diagnosis · Customer Impact · Drafted Comment (verbatim) · Related. Link at
minimum the mapped runbook — orphan notes are a bug.

### 6. Draft the comment behind the gate

Produce the comment using the progressive-investigation structure from
[[ticket-investigation-workflow]] step 5. If the server is connected, route it through
`post_comment(ticket, body, category)` — it returns `{action: 'review', body}` by default.
Show the verbatim body and get explicit approval. On approval, post via the operator's
normal path; set `posted: true` and `status: posted` in the note frontmatter.

## --poll (Phase 3)

Poll the SEV2 queue, triage each ticket not yet seen, surface every draft for review. The
dedup is server-enforced and fail-safe (a missing/corrupt state file re-triages rather than
silently skips); the orchestrator owns the vault file I/O.

### The queue (operator's "Dataplane Sev-2" saved search)

This is the exact view the operator works from — reproduce it, do not improvise the filters.
The severity floor is the filter that matters: without it the search returns hundreds of
unrelated AppSec/cert/notification tickets across the org, not the dataplane queue.

`TicketingReadActions` `search-tickets` with:

```
assignedGroup: ["Goku", "WAF-Dataplane", "WAF Dataplane Mitigation",
                "WAF Dataplane Throughput", "WAF-RestrictedRegion-Dataplane",
                "WAF Dataplane Gamma", "Stormall"]
status:         ["Assigned", "Work In Progress", "Researching", "Pending"]
currentSeverity:["1", "2", "2.5"]
sort: "lastUpdatedDate desc"
rows: 100
responseFields: ["id", "title", "currentSeverity", "extensions.tt.status",
                 "extensions.tt.assignedGroup", "lastUpdatedDate"]
```

Field-name gotchas (verified — these silently break the query if wrong):
- Status values are the SIM-T enum: `Assigned | Researching | Work In Progress | Pending |
  Resolved | Closed`. `"Open"` is NOT valid and errors the call.
- The live status lives in `extensions.tt.status`, NOT the top-level `status` field (which
  rolls everything up to `"Open"`). Read and group by `extensions.tt.status`.
- Severity filters on `currentSeverity` (string values, `"2.5"` for Daytime Sev-2). It is a
  filter only — it is NOT returned as a response field, so you cannot print per-ticket sev;
  the result count is the confirmation the filter applied (operator's view ≈ 31).
- Ticket id field is `id`, not `displayId`.

`totalResults` should match the operator's saved "Dataplane Sev-2" search. If the count is
wildly off (38, 121, …), a filter didn't apply — fix it before triaging, don't proceed on a
junk set.

Queue view vs triage scope (they are different — do not conflate):
- The search above fetches the full view: Assigned, Work In Progress, Researching, AND
  Pending. That is for visibility — what is open right now.
- Triage scope (what the agent actually investigates) is `extensions.tt.status` in
  {Assigned, Work In Progress, Researching}. Pending is view-only: it is waiting on someone
  or something (customer reply, dependency, 2-PR), so auto-investigating it is noise. Triage
  a Pending ticket only when the operator points at it by id.

1. Run the search above; collect the ticket `id`s and each ticket's `extensions.tt.status`.
2. Drop Pending tickets from the triage set (keep them only for the visibility readout).
   Triage scope = `extensions.tt.status` in {Assigned, Work In Progress, Researching}.
3. Read `AI/work/triage/.state/seen.json` (the file exists; if absent, treat as empty).
4. Filter to new tickets: `poll_new_tickets(candidates=<triage-scope ids>, seen_json=<file
   text>)` → `{new, seen_count}`. `new` is in queue order, de-duplicated within the batch.
5. For each ticket in `new`, in order:
   a. Run the flow above (classify → route → load context → dispatch → write note → draft
      behind the gate). Surface the drafted comment in chat for review — never post or pend
      autonomously while review-only.
   b. Only after the triage note is written, record it:
      `record_processed(seen_json=<current text>, ticket, classified_at=<ISO now>,
      action=<review|post|shortcut>, note_path="AI/work/triage/<TICKET>.md")` →
      `{seen_json}`. Write that back to `AI/work/triage/.state/seen.json`. Recording only
      after the note is written means a crash mid-batch re-processes rather than drops.
6. If `new` is empty, report "no new tickets" and stop — no notes, no writes.

If the `waf-dp-triage` server is not connected, fall back to reading `seen.json` directly
and skipping any ticket already keyed under `tickets`; the schema is the contract.

The notes under `AI/work/triage/` are the durable record; `seen.json` is the fast index.
`seen.json` schema (version 1): `{version, tickets: {<TICKET>: {ticket, classified_at,
action, note_path, posted}}}`.

Run from one open oncall session: `/loop 5m /om-triage --poll`. Between runs the session
stays interactive for follow-ups with full context.

## Posting modes and the shadow soak (Phase 4)

The post gate has three postures, selected by the `TRIAGE_AUTOPOST` env var (the server
reads it; the gate enforces it):

- unset / falsy → review-only. The default. Never posts; returns the drafted body. Every
  poll above runs in this mode unless you deliberately change it.
- `shadow` → dry-run autonomy. A comment that would auto-post under live mode is still held
  for review, but flagged `would_post: true` with a `shadow_record`. Nothing posts. This is
  the required gate before any category goes live.
- truthy (`1`/`true`/`yes`/`on`) → live. A comment posts autonomously only if its category
  is in the gate's per-category allowlist (`AUTOPOST_CATEGORIES`, empty until you opt one in).

Graduation path for a category — never skip the soak:

1. Run a shadow soak: set `TRIAGE_AUTOPOST=shadow`, add the candidate category to
   `AUTOPOST_CATEGORIES`, and poll for ~a week. For each `would_post` decision, append the
   `shadow_record` (from `post_comment(..., at=<ISO now>)`) to
   `AI/work/triage/.state/shadow-log.jsonl` (one JSON object per line) and keep drafting
   review-only as usual.
2. Diff would-post vs reality: compare the shadow log against the comments you actually
   posted that week. Look for any would-post the gate got wrong — wrong classification,
   stale draft, a case that needed a human. The format must be boringly correct before it
   goes live.
3. Only then flip live: set `TRIAGE_AUTOPOST=true` (or `1`) with that one category
   allowlisted. Enable one category at a time; re-soak each.

The show-before-posting rule still composes on top — even live mode is a last line, not a
replacement for operator judgment.

## Unattended operation (Phase 4)

The poll logic is identical to `--poll` above; only the driver changes:

- Interactive (today): `/loop 5m /om-triage --poll` in an open session.
- Short-term unattended: a `CronCreate` schedule or a background `claude -p "/om-triage
  --poll"` task. Both inherit the gate posture from `TRIAGE_AUTOPOST` in the environment,
  so an unattended run defaults to review-only unless you explicitly set shadow/live.
- Permanent: `/loop` and cron carry a ~7-day expiry, so neither survives long-term. For
  truly permanent operation use a launchd agent (macOS) that re-invokes the poll on an
  interval. Only the driver changes; the dedup, classify, route, and gate logic are the same.

Unattended runs cannot surface a draft in chat for live review, so they must run in
review-only or shadow mode — or in live mode only for categories that have passed the soak.
Never start an unattended live driver for a category that has not soaked.

## Related

- [[ops-triage-agent]] · [[ops-triage-agent-plan]] — project + full phased design
- [[ticket-investigation-workflow]] — the prose source this skill executes
- [[feedback_mechanic_log_download_pattern]] — download-then-grep for multi-host log fan-out
