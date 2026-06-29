---
date: 2026-06-28
description: Global Claude instructions — working principles, vault conventions, devdesk tmux rule, memory system, environment basics.
tags:
  - claude
  - global
  - conventions
  - devdesk
---

# Global Claude Instructions

## Working Principles

Behavioral defaults for all work — code, vault edits, ops, writing. Merge with project-specific instructions as needed.

Adapted from [andrej-karpathy-skills](https://github.com/forrestchang/andrej-karpathy-skills) (MIT). See [[Patterns]] for where these show up in practice.

**Tradeoff:** These guidelines bias toward caution over speed. For trivial tasks, use judgment.

### 1. Think Before Coding

**Don't assume. Don't hide confusion. Surface tradeoffs.**

Before implementing:
- State your assumptions explicitly. If uncertain, ask.
- If multiple interpretations exist, present them - don't pick silently.
- If a simpler approach exists, say so. Push back when warranted.
- If something is unclear, stop. Name what's confusing. Ask.

### 2. Simplicity First

**Minimum code that solves the problem. Nothing speculative.**

- No features beyond what was asked.
- No abstractions for single-use code.
- No "flexibility" or "configurability" that wasn't requested.
- No error handling for impossible scenarios.
- If you write 200 lines and it could be 50, rewrite it.

Ask yourself: "Would a senior engineer say this is overcomplicated?" If yes, simplify.

### 3. Surgical Changes

**Touch only what you must. Clean up only your own mess.**

When editing existing code or notes:
- Don't "improve" adjacent code, comments, or formatting.
- Don't refactor things that aren't broken.
- Match existing style, even if you'd do it differently.
- If you notice unrelated dead code, mention it - don't delete it.

When your changes create orphans:
- Remove imports/variables/functions that YOUR changes made unused.
- Don't remove pre-existing dead code unless asked.

The test: Every changed line should trace directly to the user's request.

### 4. Goal-Driven Execution

**Define success criteria. Loop until verified.**

Transform tasks into verifiable goals:
- "Add validation" → "Write tests for invalid inputs, then make them pass"
- "Fix the bug" → "Write a test that reproduces it, then make it pass"
- "Refactor X" → "Ensure tests pass before and after"

For multi-step tasks, state a brief plan:
```
1. [Step] → verify: [check]
2. [Step] → verify: [check]
3. [Step] → verify: [check]
```

Strong success criteria let you loop independently. Weak criteria ("make it work") require constant clarification.

**These guidelines are working if:** fewer unnecessary changes in diffs, fewer rewrites due to overcomplication, and clarifying questions come before implementation rather than after mistakes.

## Knowledge System

An obsidian-mind knowledge management system lives at ~/Documents/Notes/AI/.

| Folder | Purpose |
|--------|---------|
| `AI/brain/` | Core knowledge: North Star goals, Memories index, Key Decisions, Patterns, Gotchas |
| `AI/work/` | Work tracking: project artifacts (plans, investigations, design docs, validation reports), incidents, 1:1s, meeting inbox. `artifacts/<project>/` = active; `artifacts/<project>/archive/` = finished |
| `AI/perf/` | Performance: Brag Doc, competencies, evidence, review briefs |
| `AI/org/` | People and teams: person notes, team notes, org context |
| `AI/thinking/` | Session logs and scratchpad (temporary) |
| `AI/reference/` | Codebase knowledge, architecture maps |

Use `/om-standup` for morning orientation, `/om-dump` to capture information, `/om-wrap-up` to end sessions.

## Note Conventions (for files under AI/)

- Every .md file >300 chars MUST have YAML frontmatter with `date`, `description` (~150 chars), and `tags`
- Every .md file >300 chars MUST contain at least one [[wikilink]]
- Folders group by purpose; links group by meaning. A note without links is a bug.
- Use [[wikilinks]] for people, projects, concepts, and cross-references

## Memory System

All durable memories belong in vault notes under `AI/brain/` (Memories.md, Patterns.md, Key Decisions.md, Gotchas.md). Do NOT create additional memory files in `~/.claude/projects/.../memory/` beyond MEMORY.md.

## Project Initialization

When starting work in a new project for the first time:
1. Create ~/Documents/Notes/AI/work/active/<project-name>.md with frontmatter
2. Scaffold the artifacts directory: `AI/work/artifacts/<project>/` with `tasks/`, `archive/`, and a `tracker.base` (clone an existing tracker.base, swap the `project == "<slug>"` filter). Embed it in the hub via folder-qualified `![[<project>/tracker.base]]` — bare `![[tracker.base]]` is ambiguous once multiple exist. See [[feedback_project_tracker_bases]].
3. Add the project to ~/Documents/Notes/AI/work/Index.md (Active Projects + an Artifacts subsection)
4. Create a project CLAUDE.md in the project root if one doesn't exist

## Devdesk (CRITICAL — no exceptions)

**Every devdesk command runs inside tmux session `0`. No bare `ssh devdesk "<cmd>"` — ever.** This includes `ls`, `cat`, `find`, `brazil-build`, `aws`, `curl`, heredocs, one-liners, "just a quick check". The only exception is `ssh devdesk "tmux <subcmd>"` wrappers (manipulating tmux itself).

- Default pattern: `ssh devdesk "tmux list-windows -t 0"` → pick/create a window → `tmux send-keys -t 0:<win> '<cmd>' Enter` → `tmux capture-pane -t 0:<win> -p -S -60`.
- The user watches tmux session 0 live. Anything outside tmux is invisible to them.
- If you catch yourself about to type `ssh devdesk "<anything-but-tmux>"`, stop. Route it through tmux.
- See [[feedback_devdesk_tmux_workflow]] for full rules, anti-patterns, and the heredoc/helper-script guidance.

## Preferences

- Do NOT include Co-Authored-By: Claude in commit messages

## Environment

- macOS, Nix-managed config at ~/.config/nixos-config/
- Rebuild: `cd ~/.config/nixos-config && nix run .#build-switch`
- AWS/Bedrock for Claude API access
- Obsidian vault at ~/Documents/Notes/
