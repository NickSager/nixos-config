# Codex runtime

Use Codex's native tools. Keep the selected playbook's method and replace host-specific mechanics with the operations below.

## Operations

| Operation | Native mechanism |
|---|---|
| `delegate` | Use the collaboration agent tools. Give every task a bounded scope. Give each writer its own files, branch, or worktree. |
| `wait` | Use the agent wait tool for live agents. Use process handles for live commands. Do not restart work because an observation timed out. |
| `ask` | Use the native user-input tool when it is available. Otherwise ask one concise question in the final response. Ask only for decisions that Poteto Mode reserves for the human. |
| `continue` | Continue through the active goal or session until its checkable predicate passes or work reaches a genuine blocker. |
| `review` | Spawn a fresh read-only agent with the original intent, the fixed diff, and verification evidence. Inspect the artifact yourself before accepting the report. |
| `verify` | Run repository checks and use the available computer-control or product-specific tool on the real interface. Report a missing interface-control capability instead of substituting a weaker check. |
| `author` | Use Codex's `skill-creator` when it is available. Otherwise follow the selected skill-authoring playbook directly. |
| `clean` | Apply `unslop` before a commit. Inspect the diff for redundant prose that a host-specific cleanup plugin would have removed. |
| `branches` | Use Git branches and worktrees. Keep one writer per branch and one writer for shared integration state. |
| `publish` | Create or update remote review artifacts only when the user authorizes that action. Use the native hosting tools available in the session. |
| `session` | Use the active thread, goal state, and agent identifiers. Do not inspect unrelated conversation history. |

## Unsupported operations

If a playbook requires a durable wake mechanism, interface-control tool, stack manager, or remote landing feature that the current session does not expose, report `BLOCKED_RUNTIME` for that operation.
