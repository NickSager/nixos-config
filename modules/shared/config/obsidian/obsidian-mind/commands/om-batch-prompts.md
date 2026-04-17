---
description: "Fan out today's daily note prompts into parallel Claude Code sessions — one tmux window per prompt, with conflict awareness and monitoring."
---

Read today's daily note, extract the numbered prompts from `### Prompts for Today`, and launch each as a separate interactive Claude Code session in a local tmux session. Monitor all sessions until complete.

## 1. Read & Parse

Read today's daily note at `Main/Daily_Notes/YYYY/YYYY-MM/YYYY-MM-DD.md`. Find the `### Prompts for Today` section. Extract each numbered prompt (lines starting with `N.`; all indented sub-bullets and continuation lines belong to the same prompt until the next top-level number or heading). Sub-bullets within a prompt are serial sub-tasks — the spawned Claude works through them in order. Stop with a clear message if: no daily note exists, no `### Prompts for Today` section, or no numbered prompts.

## 2. Analyze Each Prompt

For each prompt determine:
- **Window name**: short kebab-case (max 20 chars) derived from the task
- **Working directory**: map to the most specific package directory under the workspace (e.g., `/Volumes/workplace/AMR/src/<PackageName>`). Fall back to workspace root for general prompts. If the prompt references a different repo, use that repo's root.
- **Build needed**: whether the task involves building or testing (implies devdesk SSH)

## 3. Conflict Detection

Compare prompts pairwise — do any target the same package or files? Present a summary table:

```
| # | Window Name | Working Dir | Conflicts |
|---|-------------|-------------|-----------|
```

For conflicts: launch in parallel but **warn the user** prominently. Each conflicting Claude will be told what the other is doing and which files to avoid. Do not block or sequence automatically.

## 4. Create Temp Files

For each prompt N, write two files:

**`/tmp/batch-prompt-N-task.txt`** — the enriched prompt:

```
## Parallel Batch Context

You are prompt N of M running in parallel from today's daily note batch.

Other sessions (DO NOT touch their files):
- Prompt 1 (<window-name>): <one-line summary> → <dir>
- Prompt 2 (<window-name>): <one-line summary> → <dir>
...
(← marks your session)

If any session conflicts with yours, the specific files to avoid are noted.

DO NOT modify files outside your working directory unless your task explicitly requires it.
If you need to build or test, SSH to devdesk (`ssh devdesk`) and build there — never locally on macOS. Workspace on devdesk: `/workplace/nsager/AMR/`. Use `brazil-build` in package dirs.

Work autonomously. Complete the task as fully as possible. Ask for permission when needed — the user is monitoring.

## Your Task

<full prompt text from daily note>
```

**`/tmp/batch-prompt-N.sh`** — launcher script:

```bash
#!/bin/bash
cd "<working-directory>"
exec claude -n "batch-<window-name>"
```

## 5. Launch Tmux Session

```bash
tmux has-session -t batch-prompts 2>/dev/null || tmux new-session -d -s batch-prompts -n control
```

Never kill an existing `batch-prompts` session — the user may have prior windows open. Just add new windows to it.

For each prompt N, sequentially:

```bash
tmux new-window -t batch-prompts: -n "<window-name>"
tmux send-keys -t "batch-prompts:<window-name>" "bash /tmp/batch-prompt-N.sh" Enter
sleep 8
tmux load-buffer -b "prompt-N" /tmp/batch-prompt-N-task.txt
tmux paste-buffer -b "prompt-N" -t "batch-prompts:<window-name>"
tmux send-keys -t "batch-prompts:<window-name>" Enter
```

Key details:
- Named buffers (`-b "prompt-N"`) prevent collision between sequential pastes
- `load-buffer`/`paste-buffer` handles arbitrary text with no escaping issues
- 8s sleep gives Claude time to start (hooks, LSP)
- Sequential launch with delay between each to avoid overwhelming the system

## 6. Report

After all windows launch, report:

```
### Batch Prompts Launched

Session: `batch-prompts`

| Window | Prompt | Dir | Status |
|--------|--------|-----|--------|

Attach: `tmux attach -t batch-prompts`
Switch windows: Ctrl-b n/p or Ctrl-b <number>

Monitoring active — I'll alert you when sessions need attention.
```

## 7. Monitor Until Complete

Enter a monitoring loop. Every 30 seconds, capture each window:

```bash
tmux capture-pane -t "batch-prompts:<window-name>" -p -S -30
```

Parse for signals:
- **Permission needed**: patterns like `Allow`, `(y/n)`, `approve`, `Do you want` → present to user with full context (what tool, what it wants to do, which file/resource). NEVER auto-approve. Show a numbered list so the user can respond like "yes for 1, always for 3, no for 2".
- **Completed**: shell prompt visible at last line, no active Claude process → mark done
- **Error/crash**: stack traces, unexpected exits → alert user
- **Working**: active output → no alert

When permissions are pending, present them like:
```
### Permissions Needed

1. **cdk-sendresponse** — Edit `index.ts`: removing inner try/catch around sendResponse
   → [yes / always / no]
2. **tests-cr-comments** — CRAddComment on CR-267652576: posting AI-assisted draft reply
   → [yes / always / no]
```

Then ask the user which to approve. Send keystrokes via `tmux send-keys` based on their response:
- "yes" → Enter (accepts highlighted option)
- "always" → arrow down to "don't ask again" option, then Enter
- "no" → arrow down to "No", then Enter

Report status changes as they happen:
```
[HH:MM] Window `<name>` needs permission — <what it wants>
[HH:MM] Window `<name>` completed
```

When all sessions finish, proceed to the harvest step.

## 8. Harvest Completed Sessions

When a window completes (or when all are done), capture and route the work into the vault. For each completed window:

**Capture the full scrollback:**
```bash
tmux capture-pane -t "batch-prompts:<window-name>" -p -S - > /tmp/batch-result-N.txt
```

The scrollback buffer is large (1M lines), so don't load the whole thing into context. Instead, extract the key outcomes:

**Read the result file selectively** — look for:
- The final Claude summary/recap (usually at the bottom, after the last tool call)
- `git diff` output or files changed
- CR comments posted (CRAddComment calls and their content)
- Plans or notes written to the vault
- Build results (pass/fail)
- Any errors or unfinished work

**Route to vault** — use the same logic as `/om-dump` to classify and route each outcome:
- Code changes → note in the relevant project file, update brag doc if significant
- CR comments posted → note the CR ID and what was said
- Plans written → verify they landed in `AI/work/plans/` with proper frontmatter and links
- Research/analysis → capture key findings in the relevant project or reference note

**Present the harvest summary:**
```
### Batch Harvest

| Window | Outcome | Vault Updates |
|--------|---------|---------------|
| cdk-sendresponse | Reverted sendResponse try/catch, build green | Updated project note, brag entry |
| payloads-automate | Wrote automation plan with 2 approaches | Plan in AI/work/plans/, project note linked |
```

After harvest, close the tmux window and clean up temp files:
```bash
tmux kill-window -t "batch-prompts:<window-name>"
rm /tmp/batch-prompt-N-task.txt /tmp/batch-prompt-N.sh /tmp/batch-result-N.txt
```

## Edge Cases

- No daily note / no section / no prompts → stop with message
- Single prompt → launch normally, still useful for session management
- Existing `batch-prompts` session → reuse it, add new windows (never kill — user may have prior windows)
- Prompts targeting different repos → use appropriate repo root as working directory

## Guidelines

- Each spawned Claude inherits the full stack automatically (CLAUDE.md, hooks, skills, MCP, memory) — no extra flags needed
- The launcher uses `#!/bin/bash` but tmux windows run zsh by default — the launcher script is executed explicitly via `bash`
- Temp files persist during execution for restart capability; clean up after batch completes
- Each session can be resumed later with `claude -r`
