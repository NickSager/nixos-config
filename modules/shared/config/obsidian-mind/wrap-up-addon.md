
## Nix-managed final hygiene

After the report above, finish these steps from the Notes vault root:

1. Run the deterministic hygiene pass and apply its safe fixes:
   `node --experimental-strip-types .claude/scripts/tidy-fix.ts --apply`.
   Report every judgment item it refuses. Do not turn those refusals into
   automatic edits.
2. Refresh both QMD indexes with
   `node --experimental-strip-types .claude/scripts/qmd-refresh-run.ts`.
   If QMD is missing or broken, report that clearly.
Never stage or commit vault content. The vault is a git repository only so Nix
activation can record the agent machinery it installs; notes stay uncommitted.
