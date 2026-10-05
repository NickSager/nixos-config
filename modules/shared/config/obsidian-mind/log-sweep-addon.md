
## Nix-managed project log sweep

From the Notes vault root, move ticked tasks off the project boards into each
project's `Log.md`:

```bash
python3 .claude/scripts/log-sweep.py --apply
```

It moves a ticked task only when every task under it is ticked, keeps the board
section and open parent as an italic prefix, groups entries by ISO week from
the `✅` date, and links agent work records filed under
`work/archive/<year>/<Project>/`. Report what it moved in one line per project.
Never delete ticked tasks by hand; the log is how "what did I do on X" gets
answered later.
