---
description: "Orchestrate Goku/WAF Dataplane ticket triage — classify, route to a runbook-backed specialist, write a vault triage note, draft a comment behind a posting gate. Wraps /om-investigate-ticket with classification and queue polling."
---

# Triage

Invoke the [[om-triage]] skill to triage a Goku/WAF Dataplane oncall ticket: classify and
route it, dispatch the mapped runbook-backed specialist (or fall through to a full
investigation), write `AI/work/triage/<TICKET-ID>.md`, and draft a ticket comment behind the
posting gate. Review-only by default — nothing posts without explicit approval.

## Usage

```
/om-triage <TICKET-ID>      # triage one ticket
/om-triage --poll           # poll the SEV2 queue and triage each new ticket (Phase 3)
```

Use `/om-investigate-ticket <TICKET-ID>` directly for the manual single-ticket path without
classification/routing. See [[ticket-investigation-workflow]] for the classify→route table
and [[ops-triage-agent]] for the project.
