---
tags: [task]
date: <% tp.date.now("YYYY-MM-DD") %>
description: "One-line task description — what + why — ~150 chars"
status: todo
priority: P2
story_points:
project:
milestone:
title: <% tp.file.title %>
due:
scheduled:
created: <% tp.date.now("YYYY-MM-DD") %>
asana_gid:
asana_url:
---

# <% tp.file.title %>

← [[tracker.base|<project tracker>]]

<One-paragraph framing: what problem, why now, what we know.>

## Acceptance

- [ ] <criterion>
- [ ] <criterion>

## Blocked by

- <link or "—">

## Related

- [[<project>]] §<section if applicable>
- <file path or related task>

## Worklog

- **<% tp.date.now("YYYY-MM-DD") %>** — created.
