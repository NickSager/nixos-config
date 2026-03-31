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

## AI Context

- `AI/Context/` — Shared context files for Claude across projects
- `AI/Agents/` — Custom agent configurations
- `AI/Skills/` — Reusable skill definitions

## Linking Conventions

- Meeting notes auto-link to daily notes via `date` frontmatter + Dataview query
- Project notes link to daily notes via `[[YYYY-MM-DD]]` in their log
- Use `[[Name]]` links for people, projects, and services throughout
