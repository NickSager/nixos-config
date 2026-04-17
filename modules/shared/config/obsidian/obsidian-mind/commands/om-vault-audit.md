# Vault Audit

Deep structural audit of the vault. Checks indexes, folder placement, frontmatter, links, Bases, and consistency. Fix what can be fixed, flag what needs user input.

**When to use**: After substantial sessions, after reorganization, or periodically to maintain vault health. For lighter end-of-session checks, use `/om-wrap-up` instead.

## Usage

```
/om-vault-audit
```

## Subagents

This command orchestrates two subagents for deep analysis:
- **`vault-librarian`** — orphan detection, broken links, frontmatter validation, stale notes, index consistency
- **`cross-linker`** — finds missing wikilinks, orphan notes, broken backlinks

Launch `vault-librarian` first for the structural audit, then `cross-linker` for link quality.

## Workflow

### 1. Check Folder Structure

Verify the vault matches the expected layout:
- `Home.md` exists at vault root
- `bases/` contains all `.base` files (none scattered elsewhere)
- `AI/work/active/` contains only notes with `status: active`
- `AI/work/archive/2025/` and `AI/work/archive/2026/` contain only `status: completed` notes
- `AI/work/incidents/` contains only notes tagged `incident`
- `AI/work/1-1/` contains only 1:1 meeting notes
- `AI/org/people/` contains only notes tagged `person`
- `AI/org/teams/` contains only notes tagged `team`
- `templates/` contains only template files (with `{{placeholders}}`)
- `AI/thinking/` is clean (no leftover drafts that should have been promoted)
- Nothing unexpected at vault root (allowed: `Home.md`, `CLAUDE.md`, `vault-manifest.json`, `CHANGELOG.md`, `CONTRIBUTING.md`, `README.md`, `LICENSE`, `.gitignore` — no user notes)

### 2. Check Indexes

Read and verify each index file:
- `Home.md` — do embedded Base views reference existing Bases? Are quick links valid?
- `AI/work/Index.md` — are active projects still active? Are completed items in the right section? Any missing notes?
- `AI/brain/Memories.md` — is the "Recent Context" section current? Any stale claims?
- `AI/org/People & Context.md` — are roles, peer selections, and project assignments current?
- `AI/perf/Brag Doc.md` — do PR counts and project descriptions match reality?
- `AI/brain/Skills.md` — are all slash commands registered? Workflows still valid?

### 3. Check Frontmatter Completeness

For each note type, verify required properties:

**Work notes** (`AI/work/active/`, `AI/work/archive/`):
- Required: `date`, `quarter`, `description`, `status`, `tags: [work-note]`
- Optional: `project`, `team`

**Incident notes** (`AI/work/incidents/`):
- Required: `date`, `quarter`, `description`, `tags: [work-note, incident]`
- Required for main incident notes: `ticket`, `severity`, `role`, `status`

**Person notes** (`AI/org/people/`):
- Required: `date`, `title`, `description`, `tags: [person]`
- Optional but recommended: `team`

**Team notes** (`AI/org/teams/`):
- Required: `date`, `description`, `tags: [team]`

**Brain notes** (`AI/brain/`):
- Required: `description`, `tags: [brain]`

**1:1 notes** (`AI/work/1-1/`):
- Required: `date`, `quarter`, `description`, `tags: [work-note]`

### 4. Check for Duplicate Tags

Scan all notes for duplicate entries in the `tags` array (e.g., `tags: [person, person]`). This is a known issue — fix any found.

### 5. Check Status/Folder Alignment

- Notes in `AI/work/active/` must have `status: active`
- Notes in `AI/work/archive/` must have `status: completed`
- No `status: active` notes in archive, no `status: completed` notes in active

### 6. Check Bases

For each `.base` file in `bases/`:
- Do filters still match the expected notes?
- Are templates excluded? (filters should include `!file.inFolder("templates")` where relevant)
- Do referenced properties exist in the target notes?
- Do formula references exist?

### 7. Check for Orphans

- Are there notes in `AI/work/active/` or `AI/work/archive/` not linked from `AI/work/Index.md`?
- Are there incident notes not linked from `AI/work/Index.md` Incidents section?
- Are there people notes not linked from `AI/org/People & Context.md`?
- Are there notes without any inbound links at all? (Use `obsidian orphans` if available, or grep for `[[NoteName]]` references)
- Are there thinking notes that should have been promoted or deleted?

### 8. Check Links

- Scan for wikilinks that reference notes that don't exist (broken links)
- Check that bidirectional links exist where expected (work note ↔ person, work note ↔ competency)
- Verify `## Related` sections aren't empty on work notes

### 9. Check for Stale Context

- Read `AI/brain/Memories.md` "Recent Context" — is anything outdated?
- Read `AI/org/People & Context.md` — any roles, teams, or relationships that changed?
- Check `AI/brain/Key Decisions.md`, `AI/brain/Patterns.md`, `AI/brain/Gotchas.md` for outdated claims
- Check `AI/brain/North Star.md` — does Current Focus reflect reality?

### 10. Check for Mixed Context

Per vault rules, each note should cover ONE concept. Flag notes that:
- Mix project work with review prep
- Mix personal conversations with project evidence
- Have 3+ independent sections that don't need each other

### 11. Check Claude Config

- `.claude/settings.json` — are hooks well-formed and referencing correct paths?
- `.claude/commands/` — do all commands reference correct folder structure?
- `CLAUDE.md` — any stale instructions that contradict current vault state?

### 12. Fix and Report

- Fix what's clearly wrong (broken links, missing frontmatter, duplicate tags, wrong folder)
- For ambiguous issues, list them and ask the user
- Summarize:
  - **Fixed**: issues resolved
  - **Flagged**: needs user input
  - **Suggested**: improvements for the vault

## Important

- Don't delete anything without asking
- Don't create new notes during audit — just fix existing ones
- Preserve existing frontmatter when editing
- If a note is in the wrong folder, move it with `git mv`
- Update `AI/brain/Memories.md` index if memory topics changed
- Use parallel agents for large audits (e.g., one checking AI/work/, one checking AI/org/, one checking AI/perf/)
