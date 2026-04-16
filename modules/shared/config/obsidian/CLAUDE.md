# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Is

An Obsidian vault for daily work tracking with AI-powered automation. Managed by nix home-manager (`~/.config/nixos-config/`).

## Key Architecture

- **Templates and prompts** are read-only nix symlinks. To edit, modify files in `~/.config/nixos-config/modules/shared/config/obsidian/` and run `nix run .#build-switch`.
- **Scripts** are mutable copies from nix. Edit here or in the nix config (nix overwrites on rebuild).
- **CLAUDE.md and AI/ files** are mutable seeds — nix creates them on first run but never overwrites edits.
- **Daily notes** use nested path: `Main/Daily_Notes/YYYY/YYYY-MM/YYYY-MM-DD.md`

## Scripts

All scripts use `claude --print` for AI processing.

```bash
scripts/slack_summary.sh [YYYY-MM-DD]          # Slack message summary
scripts/asana_daily_summary.sh [YYYY-MM-DD]    # Asana task summary
scripts/code_summary.sh YYYY-MM-DD             # Code activity summary (work only)
scripts/monthly_summary_generator.sh [YYYY-MM]  # Monthly rollup
daily-summary                                   # Shell alias: runs slack + asana
```

## AI Knowledge Base

This vault includes an [obsidian-mind](https://github.com/breferrari/obsidian-mind) knowledge management system under `AI/`.

- Use `/om-dump` to capture information, `/om-standup` for morning orientation, `/om-wrap-up` to end sessions
- Notes under `AI/` follow strict conventions: YAML frontmatter required, [[wikilinks]] mandatory
- See `AI/brain/North Star.md` for goals that guide prioritization
- See `AI/brain/Skills.md` for all available commands, agents, and workflows

### Structure
| Folder | Purpose |
|--------|---------|
| `AI/brain/` | North Star goals, Memories, Key Decisions, Patterns, Gotchas |
| `AI/work/` | Project plans, incidents, 1:1s, meeting inbox |
| `AI/perf/` | Brag Doc, competencies, evidence, review briefs |
| `AI/org/` | Person notes, team notes, org context |
| `AI/thinking/` | Session logs and scratchpad |
| `AI/reference/` | Codebase knowledge, architecture maps |

## Linking Conventions

- Meeting notes auto-link to daily notes via `date` frontmatter + Dataview query
- Project notes link to daily notes via `[[YYYY-MM-DD]]` in their log
- Use `[[Name]]` links for people, projects, and services throughout
