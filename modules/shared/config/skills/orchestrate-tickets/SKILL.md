---
name: orchestrate-tickets
description: "Use when launching or relaying ticket sessions in Herdr."
metadata:
  hermes:
    tags: [herdr, hermes, qxo, jira, orchestrator]
---

# Orchestrate ticket sessions in Herdr

The orchestrator is the Hermes session in the Herdr `Orchestrator` workspace. It launches one Herdr workspace per ticket, each running its own interactive Hermes session driven by the prompts in `reference/Ticket Prompts.md`. Nick usually talks to those sessions directly in Herdr; the orchestrator launches, relays, and reports. Poteto Mode is always on.

Require `HERDR_ENV=1`. Follow the `herdr` skill for CLI conduct.

## Launch a ticket

```bash
<skill_dir>/scripts/launch.sh COMX-1234            # cwd defaults to ~/Documents/next-gen
<skill_dir>/scripts/launch.sh COMX-1234 ~/Documents/other-repo
```

The script creates workspace `COMX-1234` with tabs Dev, Review, Agents, starts `hermes` in Agents as agent `comx-1234` (Herdr agent names must be lowercase; the workspace label keeps the key), reads the `/goal` block from `reference/Ticket Prompts.md`, replaces `<JIRA-URL>` with `https://becn.atlassian.net/browse/COMX-1234`, and submits it. Rerunning with the same key reuses the existing workspace and agent and submits the prompt again, so rerun only to resend. It never focuses anything.

For an idea rather than a ticket, pass a label instead of a key and a prompt of your own as the third argument. The Jira substitution only happens when the third argument is absent.

## Relay and report

- Status of everything: `herdr agent list` (states `working`, `blocked`, `done`, `idle`). Agent targets are the lowercased key, e.g. `comx-1234`.
- What a session is doing: `herdr agent read comx-1234 --source recent --lines 60`.
- Forward Nick's message: `herdr agent prompt comx-1234 "<text>"`. Add `--wait` only when the answer is needed now.
- When the pane shows the Draft MR URL, hand the MR watch to the same session with the `/loop` block from `reference/Ticket Prompts.md` section 2, URL substituted.
- Unattended alerting is opt-in: `herdr agent wait comx-1234 --until blocked --until done` in a background terminal with notify. Do not run it by default.

## Rules

- Never close a workspace, tab, pane, or agent the orchestrator did not create this session.
- Ticket sessions run from `~/Documents/next-gen` so they inherit its `AGENTS.md`.
- Do not edit the prompts here; `reference/Ticket Prompts.md` is the single source.
