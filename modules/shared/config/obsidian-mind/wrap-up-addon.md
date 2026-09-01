
## Nix-managed final hygiene

After the report above, finish these steps from the Notes vault root:

1. Run the deterministic hygiene pass and apply its safe fixes:
   `node --experimental-strip-types .claude/scripts/tidy-fix.ts --apply`.
   Report every judgment item it refuses. Do not turn those refusals into
   automatic edits.
2. Refresh both QMD indexes with
   `node --experimental-strip-types .claude/scripts/qmd-refresh-run.ts`.
   If QMD is missing or broken, report that clearly.
3. Stage pending content under `brain/`, `work/`, `org/`, `perf/`, `thinking/`,
   `reference/`, `memories/`, and `Home.md`. Do not stage agent machinery or
   Nix-managed marker files.
4. If the staged content diff is nonempty, commit it with a short message that
   describes the session. If it is empty, exit successfully without a commit.

This is the commit point for vault content. Nix activation commits only pinned
agent machinery and leaves content changes for wrap-up.
