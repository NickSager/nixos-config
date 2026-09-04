# Claude Code runtime

Use Claude Code's native tools. Keep the selected playbook's method and replace host-specific mechanics with the operations below.

## Operations

| Operation | Native mechanism |
|---|---|
| `delegate` | Use the native task or subagent tool. Use a background task when the playbook asks for background work. Give each writer its own branch or worktree. |
| `wait` | Use native task status and completion results. Poll only a confirmed live task or process. |
| `ask` | Use the native user-input tool only for decisions that Poteto Mode reserves for the human. |
| `continue` | Continue in the current session while work can make progress. Use the host's durable task mechanism when one is available. |
| `review` | Start a fresh read-only task with the original intent, the fixed diff, and verification evidence. |
| `verify` | Run repository checks and drive the real interface with tools available in the current session. Report a missing interface-control capability instead of substituting a weaker check. |
| `author` | Use the available skill-authoring capability. If none exists, follow the selected skill-authoring playbook directly. |
| `clean` | Apply the available prose-cleanup skill before a commit. If none exists, apply Poteto Mode's writing rules directly and inspect the resulting diff. |
| `branches` | Use Git branches and worktrees. Keep one writer per branch and one writer for shared integration state. |
| `publish` | Create or update remote review artifacts only when the user authorizes that action. Use plain Git hosting tools available in the session. |
| `session` | Use the current conversation and native task identifiers. Do not inspect unrelated conversation history. |

## Unsupported operations

If a playbook requires a durable wake mechanism, interface-control tool, stack manager, or remote landing feature that the current session does not expose, report `BLOCKED_RUNTIME` for that operation.
