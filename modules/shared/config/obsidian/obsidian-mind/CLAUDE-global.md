# Global Claude Instructions

## Knowledge System

An obsidian-mind knowledge management system lives at ~/Documents/Notes/AI/.

| Folder | Purpose |
|--------|---------|
| `AI/brain/` | Core knowledge: North Star goals, Memories index, Key Decisions, Patterns, Gotchas |
| `AI/work/` | Work tracking: project plans, incidents, 1:1s, meeting inbox |
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
2. Add the project to ~/Documents/Notes/AI/work/Index.md
3. Create a project CLAUDE.md in the project root if one doesn't exist

## Preferences

- Do NOT include Co-Authored-By: Claude in commit messages

## Environment

- macOS, Nix-managed config at ~/.config/nixos-config/
- Rebuild: `cd ~/.config/nixos-config && nix run .#build-switch`
- AWS/Bedrock for Claude API access
- Obsidian vault at ~/Documents/Notes/
