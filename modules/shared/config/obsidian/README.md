# First-Run Setup (Nix-Managed Vault)

These steps are only needed once after `nix run .#build-switch` on a fresh machine.
Everything else (vault structure, templates, prompts, scripts) is handled by nix.

## 1. Open the vault

1. Launch Obsidian
2. Select "Open folder as vault"
3. Navigate to `~/Documents/Notes/`
4. Trust the vault when prompted

## 2. Enable community plugins

1. Settings -> Community Plugins -> Turn on community plugins

## 3. Install plugins

Browse and install each of these (Settings -> Community Plugins -> Browse):

**Essential:**
- Tasks
- Day Planner
- Dataview
- Templater
- Natural Language Dates

**Recommended:**
- Advanced Tables
- PlantUML
- Emoji Shortcodes

**Optional (Amazon-specific):**
- PhoneTool
- Quip

## 4. Configure Daily Notes

1. Settings -> Core Plugins -> enable "Daily Notes"
2. Set daily notes folder: `Main/Daily_Notes/YYYY/YYYY-MM`
3. Set date format: `YYYY-MM-DD`
4. Set template location: `Main/Templates/Daily_Note.md`

## 5. Configure Templater

1. Settings -> Templater
2. Set template folder: `Main/Templates`
3. Enable "Automatic jump to cursor"

## 6. Install slack-cli

The Slack summary scripts require [Thsvaugh-SlackCLI](https://code.amazon.com/packages/Thsvaugh-SlackCLI/trees/mainline):

1. Clone and install following the package README
2. Configure with your Slack workspace credentials
3. Test: `slack-cli search "from:@$USER on:$(date +%Y-%m-%d)"`

Optionally set `SLACK_USERNAME` in your shell env if your Slack handle differs
from `$USER`.

## 7. Configure scripts

Edit `~/Documents/Notes/scripts/taskei_daily_summary.sh` and set `ROOM_ID` to
your team's Taskei room ID. Find it with `taskei rooms list`.

## 8. Test

```bash
# Create a daily note in Obsidian first, then:
~/Documents/Notes/scripts/slack_summary.sh $(date +%Y-%m-%d)
~/Documents/Notes/scripts/taskei_daily_summary.sh $(date +%Y-%m-%d)
```

---

# Obsidian Daily Work Tracking System

A complete system for tracking daily work activities using Obsidian, with AI-powered automation for aggregating Slack messages, task updates, and generating monthly summaries.

Based on [Thsvaugh-ObsidianDailySetup](https://code.amazon.com/packages/Thsvaugh-ObsidianDailySetup/trees/mainline).
See the associated blog post at [Obsidian for Daily Work Tracking](https://w.amazon.com/bin/view/Users/thsvaugh/Blog/2025-11-17_obsidian_work_tracking_setup/).

## Overview

This repository contains all the necessary scripts, templates, and prompts to set up a comprehensive work tracking system in Obsidian. The system combines manual note-taking with automated data collection to create searchable, comprehensive work logs.

**Key Features:**
- Structured daily notes with task management integration
- Automated Slack message summaries
- Task management system integration (Taskei)
- Monthly summary generation
- PhoneTool integration for contact management
- Time tracking for meetings

## Quick Start

### Prerequisites

1. **Obsidian** - Installed via nix (shared packages)
2. **Amazon Q CLI** - Install following [AWS documentation](https://docs.aws.amazon.com/amazonq/latest/qdeveloper-ug/command-line-getting-started-installing.html)
3. **jq** - Installed via nix (shared packages)
4. **slack-cli** - Download from [Thsvaugh-SlackCLI on Code](https://code.amazon.com/packages/Thsvaugh-SlackCLI/trees/mainline)
5. **taskei** - Amazon's internal task management CLI (optional, for task integration)

### Nix-Managed Installation

This vault is bootstrapped automatically by `nix run .#build-switch`. The nix config:
- Creates the vault directory at `~/Documents/Notes/`
- Symlinks templates and prompts (read-only, managed by nix)
- Copies scripts as mutable files (so relative paths work)
- Creates mutable directories for daily notes, meeting notes, etc.
- Places this README in the vault root

After building, open `~/Documents/Notes/` as a vault in Obsidian.

### Install Required Plugins

Go to Settings -> Community Plugins -> Browse and install:

**Essential:**
- Tasks
- Day Planner
- Dataview
- Templater
- Natural Language Dates

**Optional but Recommended:**
- PhoneTool (Amazon-specific)
- PlantUML
- Mindmap NextGen
- Marp Slides
- Emoji Shortcodes
- Advanced Tables

See [Plugin List](#complete-plugin-list) for full details.

### Configure Obsidian

**Daily Notes Setup:**
1. Settings -> Core Plugins -> Daily Notes (enable)
2. Daily notes folder: `Main/Daily_Notes/YYYY/YYYY-MM`
3. Date format: `YYYY-MM-DD`
4. Template location: `Main/Templates/Daily_Note.md`

**Templater Setup:**
1. Settings -> Templater
2. Enable "Automatic jump to cursor"
3. Template folder: `Main/Templates`

### Test the System

Create a daily note and run the scripts manually:

```bash
# Create today's daily note in Obsidian first, then:
~/Documents/Notes/scripts/slack_summary.sh $(date +%Y-%m-%d)
~/Documents/Notes/scripts/taskei_daily_summary.sh $(date +%Y-%m-%d)
```

## Directory Structure

```
~/Documents/Notes/
├── Main/
│   ├── Daily_Notes/           # Daily notes organized by year/month (mutable)
│   │   └── YYYY/
│   │       └── YYYY-MM/
│   │           ├── YYYY-MM-DD.md
│   │           └── monthly_summary.md
│   ├── Templates/             # Obsidian templates (nix-managed symlinks)
│   │   ├── Daily_Note.md
│   │   └── PhoneTool Template.md
│   ├── Phonetool/            # Contact network (mutable)
│   └── Meeting_Notes/        # Meeting notes (mutable)
├── scripts/                  # Automation scripts (copied by nix, mutable)
│   ├── common_summary_functions.sh
│   ├── slack_summary.sh
│   ├── taskei_daily_summary.sh
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
3. Uses Amazon Q CLI to process and categorize messages
4. Updates daily note with formatted Slack Summary section

**Requirements:**
- `slack-cli` tool installed and configured
- Amazon Q CLI with file read/write permissions
- Daily note must already exist for the target date

### taskei_daily_summary.sh

Generates daily task management summaries.

**Usage:**
```bash
./scripts/taskei_daily_summary.sh YYYY-MM-DD [TIMEZONE]
```

**Configuration:**
- Edit `ROOM_ID` in the script for your Taskei room
- Username automatically detected from `$USER`
- Default timezone: `America/New_York`

### monthly_summary_generator.sh

Generates comprehensive monthly summaries.

**Usage:**
```bash
./scripts/monthly_summary_generator.sh YYYY-MM
```

## Templates

### Daily_Note.md

Structured template for daily notes with:
- Frontmatter (tags, confidentiality markers)
- Task query sections (overdue, due this week, no due date)
- Day planner sections (Work, Ad-Hoc, Meetings, Issues, Notes)
- Automatic time tracking integration

### PhoneTool Template.md

Contact page template with:
- Frontmatter metadata (name, role, contact info, aliases)
- Quick links (PhoneTool, Slack, email, LinkedIn, SayMyName)
- Dataview query for profile display
- Automatic meeting/mention tracking

## Automation Setup

### Option 1: Cron Jobs (Recommended)

Add to crontab (`crontab -e`):

```bash
# Run Slack summary at 7 PM daily
0 19 * * * ~/Documents/Notes/scripts/slack_summary.sh >> /tmp/slack_summary.log 2>&1

# Run Taskei summary at 7:30 PM daily
30 19 * * * ~/Documents/Notes/scripts/taskei_daily_summary.sh >> /tmp/taskei_summary.log 2>&1

# Run monthly summary on the 1st of each month at 8 AM
0 8 1 * * ~/Documents/Notes/scripts/monthly_summary_generator.sh >> /tmp/monthly_summary.log 2>&1
```

### Option 2: Manual Execution

Use the shell alias (added by nix home-manager zsh config):

```bash
daily-summary
```

## Daily Workflow

### Morning
1. Open Obsidian and create today's daily note (Ctrl+T or Cmd+T)
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
2. Run `daily-summary` or let cron jobs handle it
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
| PhoneTool | Import contact data from Amazon PhoneTool | Optional* |
| Advanced Tables | Enhanced table editing | Recommended |
| Emoji Shortcodes | Quick emoji insertion | Recommended |
| Emoji Toolbar | Emoji picker | Recommended |
| Image Toolkit | Enhanced image viewing | Recommended |
| Marp Slides | Create presentations from markdown | Optional |
| Mindmap NextGen | Auto-generated mindmaps | Optional |
| PlantUML | Technical diagrams | Recommended |
| Quip | Document integration | Optional* |
| Style Settings | Custom CSS configuration | Optional |
| Super Simple Time Tracker | Detailed time tracking | Optional |
| Vim Yank Highlight | Visual feedback for vim users | Optional |

\* Amazon-specific plugins

## Troubleshooting

### Scripts fail with "command not found"

```bash
for cmd in q slack-cli taskei jq; do
    command -v "$cmd" >/dev/null || echo "Missing: $cmd"
done
```

### "Daily log file does not exist"

Create the daily note in Obsidian first, then run the script.

### Slack summary shows no messages

1. Test `slack-cli` manually: `slack-cli search "from:@your-username on:2025-11-14"`
2. Check `~/.cache/slack_summary/YYYY-MM-DD/` for raw data

## Acknowledgments

- Original setup by [thsvaugh](https://code.amazon.com/packages/Thsvaugh-ObsidianDailySetup/trees/mainline)
- Built using [Obsidian](https://obsidian.md)
- Automation powered by [Amazon Q CLI](https://aws.amazon.com/q/)
- Inspired by the [Zettelkasten](https://zettelkasten.de/) method and [Getting Things Done](https://gettingthingsdone.com/)
