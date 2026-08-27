# Notes vault instructions

`~/Documents/Notes` is the human Obsidian vault for daily work tracking. It is
separate from the agent knowledge vault at `~/Documents/Mind`.

## Managed content

- Templates and prompts are read-only Nix symlinks. Edit their sources in
  `~/.config/nixos-config/modules/shared/config/obsidian/`, then rebuild.
- Scripts under `scripts/` are mutable copies managed by Home Manager and can
  be overwritten on the next rebuild.
- Daily notes live at `Main/Daily_Notes/YYYY/YYYY-MM/YYYY-MM-DD.md`.

## Agent boundary

Do not create or use a `Notes/AI` knowledge base. Agent instructions, skills,
and durable knowledge belong in `~/Documents/Mind`; use `/om-standup`,
`/om-dump`, and `/om-wrap-up` there. This vault has no automatic sync or
wikilink bridge to Mind.

## Automation

The available vault scripts are `slack_summary.sh`, `asana_daily_summary.sh`,
and `monthly_summary_generator.sh`. They use `claude --print`; review their
output before treating it as a record of work.
