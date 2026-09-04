# Generic runtime

Use this runtime only when the host is unknown. It supports bounded, sequential, local work.

## Operations

| Operation | Native mechanism |
|---|---|
| `delegate` | Run optional delegated work in the current context. If the playbook requires a separate worker, report `BLOCKED_RUNTIME`. |
| `wait` | Wait only on a process handle that the current session created and can inspect. |
| `ask` | Ask one concise question only for decisions that Poteto Mode reserves for the human. |
| `continue` | Continue while the current session remains active. Do not claim durable continuation. |
| `review` | Review the artifact in the current context only when the playbook permits self-review. If the playbook requires an independent reviewer, report `BLOCKED_RUNTIME`. |
| `verify` | Run local repository checks. Report when the real interface cannot be exercised. |
| `author` | Follow the selected skill-authoring playbook directly. Report `BLOCKED_RUNTIME` if it requires unavailable validation. |
| `clean` | Apply Poteto Mode's writing rules directly and inspect the resulting diff. |
| `branches` | Use the current Git branch. Do not start concurrent writers. |
| `publish` | Do not publish or land remote changes. |
| `session` | Use only the current session. |

## Unsupported operations

Report `BLOCKED_RUNTIME` when a playbook requires independent workers, durable continuation, background notifications, concurrent writers, interface control, stack management, or remote landing.
