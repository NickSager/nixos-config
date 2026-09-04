# Cursor runtime

Use Cursor's existing pstack mechanics. Concrete Cursor instructions in upstream playbooks remain authoritative unless this reference says otherwise.

## Operations

| Operation | Native mechanism |
|---|---|
| `delegate` | Use the `Task` tool. Prefer the named `poteto-agent`. Use a general-purpose agent when that role is unavailable. Preserve `model`, `environment`, `run_in_background`, and `readonly`. |
| `wait` | Use Cursor completion notifications for ordinary workers. Use a watcher and Cursor's `/loop` for durable polling. |
| `ask` | Use `AskQuestion` only for the human decisions allowed by Poteto Mode. |
| `continue` | Use Cursor's `/loop` for one long-running task. Use the selected autonomous playbook for a queue or program. |
| `review` | Use a fresh `Task` reviewer. Use the model and isolation that the selected review skill requires. |
| `verify` | Use `control-cli` or `control-ui` from `cursor-team-kit` when the selected playbook requires live verification. |
| `author` | Use Cursor's `create-skill` capability for skill authoring. |
| `clean` | Use `deslop` from `cursor-team-kit` before a commit when the selected playbook requires it. |
| `branches` | Use Git worktrees and Graphite exactly as the selected Cursor playbook specifies. |
| `publish` | Follow the selected opening, babysit, or shipping playbook. Keep its explicit merge authorization gate. |
| `session` | Use Cursor transcripts and cloud-agent state only where the selected playbook names them. |

## Unsupported operations

None beyond the limits stated by the selected playbook and the tools available in the current session.
