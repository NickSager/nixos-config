# Hermes runtime

Use Hermes sessions, delegation, and goal mode. The active profile owns credentials, model defaults, memory, skills, and session state.

## Operations

| Operation | Native mechanism |
|---|---|
| `delegate` | Use `delegate_task` for bounded research, implementation, or review. Let the active profile choose its configured delegation model unless the task requires an explicit supported override. |
| `wait` | Let Hermes manage a delegated task or goal. Use gateway and Kanban events for durable worker notifications. Do not keep a conversational session alive with a polling loop. |
| `ask` | Ask in the active session only for decisions that Poteto Mode reserves for the human. Mark unattended Kanban work blocked when approved requirements remain ambiguous. |
| `continue` | Use one normal session for bounded work. Use `/goal` when one task has a checkable completion predicate and must continue across turns. |
| `review` | Delegate a fresh review with the original intent, the fixed commit or diff, and verification evidence. Keep the reviewer separate from the writer when the profile configuration permits it. |
| `verify` | Run repository checks and use tools available to the active profile on the real interface. Report a missing interface-control capability instead of substituting a weaker check. |
| `author` | Use the installed skill-authoring skill when one is available. Otherwise follow the selected skill-authoring playbook directly. |
| `clean` | Apply the installed prose-cleanup skill before a commit. If none exists, apply Poteto Mode's writing rules directly and inspect the resulting diff. |
| `branches` | Use an isolated worktree and branch for each writer. Use one integration worker for shared local branch state. |
| `publish` | Keep remote pushes, deployments, production changes, and remote landing disabled unless the user authorizes them. |
| `session` | Resume persisted Hermes sessions through Hermes. Do not attach a session across profile boundaries. |

## Kanban boundary

One substantial task stays in one session and uses `/goal` when it needs durable continuation. An approved multi-ticket program uses the separate `implement-tickets` skill and Hermes Kanban. Do not add Kanban to a single task only because the task is long.

## Unsupported operations

If a playbook requires a stack manager, remote landing, or an interface-control capability that Hermes does not expose, report `BLOCKED_RUNTIME` for that operation.
