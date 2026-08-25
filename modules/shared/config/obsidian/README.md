# Obsidian Daily Work Tracking System

A complete system for tracking daily work activities using Obsidian, with AI-powered automation for aggregating Slack messages, task updates, and generating monthly summaries.

Originally adapted from an internal daily-work-tracking setup shared by a coworker.

## Overview

This repository contains all the necessary scripts, templates, and prompts to set up a comprehensive work tracking system in Obsidian. The system combines manual note-taking with automated data collection to create searchable, comprehensive work logs.

**Key Features:**
- Structured daily notes with task management integration
- Automated Slack message summaries
- Task management summaries via Asana (optional, through an Asana MCP server)
- Monthly summary generation
- Time tracking for meetings

## Quick Start

### Prerequisites

1. **Obsidian** - Installed via nix (shared packages)
2. **Claude Code** - the `claude` CLI, used to process and summarize captured data
3. **jq** - Installed via nix (shared packages)
4. **slack-cli** - a Slack CLI exposing `slack-cli search ... --format llm` (this repo assumes a custom/internal build; swap in your own Slack export tool if you don't have one)

### Nix-Managed Installation

This vault is bootstrapped automatically by `nix run .#build-switch`. The nix config:
- Creates the vault directory at `~/Documents/Notes/`
- Installs and configures all community plugins declaratively
- Configures core plugins (Daily Notes, Templates) with correct settings
- Configures Templater (auto-jump to cursor, folder templates)
- Sets hotkeys (Cmd+N opens today's daily note)
- Symlinks templates and prompts (read-only, managed by nix)
- Copies scripts as mutable files (so relative paths work)
- Creates mutable directories for daily notes, meeting notes, etc.
- Places this README in the vault root

After building, open `~/Documents/Notes/` as a vault in Obsidian and enable
community plugins (one-time toggle in Settings -> Community Plugins).

### Test the System

Create a daily note and run the scripts manually:

```bash
# Create today's daily note in Obsidian first, then:
~/Documents/Notes/scripts/slack_summary.sh $(date +%Y-%m-%d)
~/Documents/Notes/scripts/asana_daily_summary.sh $(date +%Y-%m-%d)
```

## Directory Structure

```
~/Documents/Notes/
├── Main/
│   ├── Daily_Notes/           # Daily notes (mutable)
│   │   └── YYYY-MM-DD.md
│   ├── Templates/             # Obsidian templates (nix-managed symlinks)
│   │   └── Daily_Note.md
│   └── Meeting_Notes/        # Meeting notes (mutable)
├── scripts/                  # Automation scripts (copied by nix, mutable)
│   ├── common_summary_functions.sh
│   ├── slack_summary.sh
│   ├── asana_daily_summary.sh
│   └── monthly_summary_generator.sh
├── prompts/                  # AI prompts for processing (nix-managed symlinks)
│   ├── slack_aggregate.md
│   ├── slack_rolling_summary_prompt.md
│   ├── monthly_summary_prompt.md
│   ├── deliverables_prompt.md
│   └── slack_log.md
└── README.md
```

## Scripts

### common_summary_functions.sh

Shared utility functions used by all summary scripts:
- `init_script_env()` - Initialize environment and load aliases
- `setup_paths()` - Configure directory paths
- `process_date_arg()` - Handle date arguments and auto-detection
- `validate_daily_log()` - Ensure daily note exists
- `create_work_dir()` - Create working directory in `~/.cache/`

### slack_summary.sh

Generates daily Slack message summaries.

**Usage:**
```bash
./scripts/slack_summary.sh YYYY-MM-DD
# Or run without args to process most recent day without summary
./scripts/slack_summary.sh
```

**What it does:**
1. Fetches Slack messages for the specified date using `slack-cli`
2. Handles pagination with rolling summaries for large message volumes
3. Uses Claude Code (`claude`) to process and categorize messages
4. Updates daily note with formatted Slack Summary section

**Requirements:**
- `slack-cli` tool installed and configured
- `claude` CLI with file read/write permissions
- Daily note must already exist for the target date

**Installing slack-cli:**

The Slack summary script expects a `slack-cli` binary that supports
`slack-cli search "..." --format llm`. Install/configure whatever Slack CLI
you have access to, then:

1. Configure it with your Slack workspace credentials
2. Test: `slack-cli search "from:@$USER on:$(date +%Y-%m-%d)"`

Optionally set `SLACK_USERNAME` in your shell env if your Slack handle differs
from `$USER`.

### asana_daily_summary.sh

Generates daily task management summaries from Asana.

**Usage:**
```bash
./scripts/asana_daily_summary.sh YYYY-MM-DD
```

**What it does:**
1. Asks Claude Code to fetch Asana tasks updated on the given date (via an Asana MCP server)
2. Summarizes task names, status changes, and comments
3. Updates daily note with an Asana Summary section

**Requirements:**
- An Asana MCP server configured for the `claude` CLI (the script skips gracefully if none is available)

### monthly_summary_generator.sh

Generates comprehensive monthly summaries.

**Usage:**
```bash
./scripts/monthly_summary_generator.sh YYYY-MM
```

## Templates

### Daily_Note.md

Structured template for daily notes with:
- Task query sections (overdue, due this week, no due date)
- Day planner sections (Work, Ad-Hoc, Meetings, Issues, Notes)
- Automatic time tracking integration

## Automation Setup

### Option 1: Cron Jobs (Recommended)

Add to crontab (`crontab -e`):

```bash
# Run Slack summary at 7 PM daily
0 19 * * * ~/Documents/Notes/scripts/slack_summary.sh >> /tmp/slack_summary.log 2>&1

# Run Asana summary at 7:30 PM daily
30 19 * * * ~/Documents/Notes/scripts/asana_daily_summary.sh >> /tmp/asana_summary.log 2>&1

# Run monthly summary on the 1st of each month at 8 AM
0 8 1 * * ~/Documents/Notes/scripts/monthly_summary_generator.sh >> /tmp/monthly_summary.log 2>&1
```

### Option 2: Manual Execution

Run the scripts directly:

```bash
cd ~/Documents/Notes && ./scripts/slack_summary.sh && ./scripts/asana_daily_summary.sh
```

## Daily Workflow

### Morning
1. Open Obsidian and press Cmd+N to open today's daily note
2. Review task queries (overdue, due this week)
3. Add planned work to the "Ad-Hoc" section
4. Link to relevant people and projects using `[[Name]]`

### Throughout the Day
1. Check off meetings as they occur (Day Planner tracks time automatically)
2. Add meeting notes under each meeting with attendees as links
3. Document issues in the "Issues" section with resolution steps
4. Add ad-hoc work and decisions to "Notes" section

### End of Day
1. Review your manual notes
2. Run the summary scripts manually or let cron jobs handle it
3. Review generated summaries for accuracy
4. Edit as needed to add missing context

### Monthly
1. Run `~/Documents/Notes/scripts/monthly_summary_generator.sh`
2. Review the generated `monthly_summary.md`
3. Use for performance reviews, retrospectives, or status reporting

## Complete Plugin List

| Plugin | Purpose | Priority |
|--------|---------|----------|
| Tasks | Advanced task management with GTD features | Essential |
| Day Planner | Time-blocking and automatic meeting time tracking | Essential |
| Dataview | SQL-like queries for data aggregation | Essential |
| Templater | Dynamic templates with variables and scripting | Essential |
| Natural Language Dates | Parse dates from natural language | Essential |
| Advanced Tables | Enhanced table editing | Recommended |
| Emoji Shortcodes | Quick emoji insertion | Recommended |
| Emoji Toolbar | Emoji picker | Recommended |
| Image Toolkit | Enhanced image viewing | Recommended |
| Marp Slides | Create presentations from markdown | Optional |
| Mindmap NextGen | Auto-generated mindmaps | Optional |
| PlantUML | Technical diagrams | Recommended |
| Quip | Document integration | Optional |
| Style Settings | Custom CSS configuration | Optional |
| Super Simple Time Tracker | Detailed time tracking | Optional |
| Vim Yank Highlight | Visual feedback for vim users | Optional |

## Troubleshooting

### Scripts fail with "command not found"

```bash
for cmd in claude slack-cli jq; do
    command -v "$cmd" >/dev/null || echo "Missing: $cmd"
done
```

### "Daily log file does not exist"

Create the daily note in Obsidian first, then run the script.

### Slack summary shows no messages

1. Test `slack-cli` manually: `slack-cli search "from:@your-username on:2025-11-14"`
2. Check `~/.cache/slack_summary/YYYY-MM-DD/` for raw data

## Acknowledgments

- Original setup shared by a coworker
- Built using [Obsidian](https://obsidian.md)
- Automation powered by [Claude Code](https://claude.com/product/claude-code)
- Inspired by the [Zettelkasten](https://zettelkasten.de/) method and [Getting Things Done](https://gettingthingsdone.com/)
