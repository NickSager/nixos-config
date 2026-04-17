# Auto Memory

All project memories live in the vault (git-tracked). This file is a lightweight index.

## Rule: Vault-First Memories

**All new memories for this project MUST be written to vault notes in `brain/`, NOT to files in this directory.**

- Durable knowledge → `brain/` notes (git-tracked, Obsidian-browsable, linked)
- This `MEMORY.md` → index only, pointers to vault locations
- Never create new `.md` files in this `~/.claude/` memory directory — they aren't version-controlled

## Where to Find Things

| Topic | Vault Location |
|-------|---------------|
| Technical gotchas | `AI/brain/Gotchas.md` |
| Patterns and conventions | `AI/brain/Patterns.md` |
| Key decisions | `AI/brain/Key Decisions.md` |
| Goals and focus | `AI/brain/North Star.md` |
| Slash commands and skills | `AI/brain/Skills.md` |
| People and org context | `AI/org/People & Context.md` |
| Active work and projects | `AI/work/Index.md` |
| Performance evidence | `AI/perf/Brag Doc.md` |

## Setup

1. Find your project memory path: `~/.claude/projects/<encoded-path>/memory/`
2. Copy this file there as `MEMORY.md`
3. Claude Code will auto-load it at the start of every conversation
4. When Claude creates memories, they go to vault notes — not this directory
