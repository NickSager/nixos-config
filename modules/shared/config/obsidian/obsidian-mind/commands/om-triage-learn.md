---
description: "Mine closed Goku/WAF triage notes for recurring patterns not yet in the runbooks and propose runbook appends as a diff for approval. Never auto-edits runbooks or posts to tickets."
---

# Triage Learn

Invoke the [[om-triage-learn]] skill to fold field knowledge from accumulated triage notes
back into the runbooks. It QMD-searches `AI/work/triage/` for recurring root causes,
decisive diagnostics, and resolution signatures not yet documented, then writes a proposal
under `AI/work/artifacts/ops-triage-agent/` with runbook-ready text and citations. Read-only
over the runbooks — the operator reviews and applies every change.

## Usage

```
/om-triage-learn              # mine all categories
/om-triage-learn <category>   # focus one alarm family (e.g. failopen)
```

See [[ops-triage-agent]] for the project and [[ticket-investigation-workflow]] for the
category → runbook map.
