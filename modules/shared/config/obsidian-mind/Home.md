---
date: 2026-09-09
description: "Vault entry point — embedded dashboards, quick links, current focus"
tags:
  - index
---

# Home

## Current Focus

![[North Star#Current Focus]]

## Projects

| Project | What it is | Board |
| --- | --- | --- |
| [[Takeoff]] | AI insulation takeoff and quoting for TruTeam (primary) | [[Takeoff#Build progress\|Build progress]] |
| [[Ops]] | NextGen maps, ComX contractors, Jira workflow | |
| [[Hiring]] | Interview loops and scorecards | |
| [[Setup]] | Machine, access, local dev | [[Setup/Log\|Setup Log]] |

## Active Work

Every open task in `work/active/`, soonest due first. Check tasks off in their note; [[Open Tasks]] has the same list as clickable checkboxes.

```dataview
TABLE WITHOUT ID
  regexreplace(t.text, "\\s*📅\\s*\\d{4}-\\d{2}-\\d{2}", "") AS Task,
  t.due AS Due,
  split(t.path, "/")[2] AS Project,
  file.link AS Note
FROM "work/active"
FLATTEN file.tasks AS t
WHERE !t.completed AND t.status != "-"
SORT default(t.due, date("2999-12-31")) ASC, split(t.path, "/")[2] ASC
```

## Recently Touched

![[Home.base#Recently Touched]]

## Incidents

![[Incidents.base#All Incidents]]

## Quick Links

- [[Index|Work Notes]] | [[People & Context]] | [[Brag Doc]]
- [[Memories]] | [[North Star]] | [[Skills]]

## Recent 1:1s

![[1-1 History.base#All 1:1s]]

## People

![[People Directory.base#By Team]]
