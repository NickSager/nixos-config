
## Select the host runtime

Before you copy a playbook into the todolist, identify the current host from the system instructions and available tools. Do not infer the host from repository files or environment variables. Select exactly one runtime and read its reference in full:

- Cursor uses [`references/runtimes/cursor.md`](references/runtimes/cursor.md).
- Claude Code uses [`references/runtimes/claude.md`](references/runtimes/claude.md).
- Codex uses [`references/runtimes/codex.md`](references/runtimes/codex.md).
- Hermes uses [`references/runtimes/hermes.md`](references/runtimes/hermes.md).
- An unknown host uses [`references/runtimes/generic.md`](references/runtimes/generic.md).

The selected runtime translates these operations: `delegate`, `wait`, `ask`, `continue`, `review`, `verify`, `author`, `clean`, `branches`, `publish`, and `session`. Runtime instructions override concrete host commands, plugins, and named host skills in upstream playbooks. They do not change the playbook's engineering method, completion criteria, safety boundaries, or review requirements.

If the selected runtime does not implement a required operation, report `BLOCKED_RUNTIME` with the operation and the missing capability. Do not invent a command or switch to another host's adapter.

When a host has no named `poteto-agent` role, use its native delegation operation. Tell the worker to read Poteto Mode and each applicable `principle-*` skill before work. Pass file paths instead of large inline payloads. Preserve the requested model role, background behavior, and read-only or writable boundary when the host supports them.
