## Project work recording

Before finishing a task that changed files, made a durable decision, or
produced verified findings, call the OM MCP `record_work` tool. Include a
specific title, a short summary, the changed files or components, decisions
and their reasons, verification performed, lessons learned, and unresolved
issues. Write for a future session that cannot see the current conversation.

Do not ask whether to record the work. Skip this only for conversation and
tasks with no durable result. If OM is unavailable, report that failure in the
final response instead of silently dropping the record.

## Poteto execution routing

When Poteto Mode runs in Hermes, select the Hermes runtime reference before
the playbook. Keep the active profile's credentials, model defaults, memory,
skills, and sessions for the full task.

- Run bounded work in the current session. Use `delegate_task` for bounded
  research or review when delegation helps.
- Use `/goal` when one task has a checkable completion condition and must
  continue across turns.
- Use `implement-tickets` and Hermes Kanban only for an approved multi-ticket
  program that needs durable independent workers or dependency tracking. If
  that skill is unavailable, report `BLOCKED_RUNTIME` instead of inventing the
  workflow.

Do not use Kanban only because one task is long. Do not move a task across
profile boundaries.
