#!/usr/bin/env python3
"""Move ticked tasks off each project board into the project's Log.md.

A project is a folder `work/active/<Project>/` whose board is `<Project>.md`.
A ticked task moves only when every task beneath it is ticked too; its child
lines move with it verbatim. The open ancestors and the board section it sat
under are kept as a context prefix so a sub-item still reads on its own.

Entries land under an ISO-week heading taken from the task's `✅ YYYY-MM-DD`
completion date (today when it has none), newest week first. The sweep also
links agent work records filed under `work/archive/<year>/<Project>/`, so the
log answers "what did I do on X" for both hand and agent work.

Dry run by default; `--apply` writes. Re-running is a no-op: swept tasks are
gone from the board, and records already linked are skipped.
"""

from __future__ import annotations

import argparse
import datetime as dt
import re
import sys
from pathlib import Path

TASK = re.compile(r"^(\s*)- \[([ xX])\] (.*)$")
BULLET = re.compile(r"^(\s*)- (.*)$")
HEADING = re.compile(r"^(#+) (.*)$")
DONE = re.compile(r"✅ (\d{4}-\d{2}-\d{2})")
WEEK = re.compile(r"^## (\d{4})-W(\d{2})\b")
RECORD = re.compile(r"^(\d{4}-\d{2}-\d{2})-.*\.md$")


def width(line: str) -> int:
    return len(line.expandtabs(4)) - len(line.expandtabs(4).lstrip())


def block_end(lines: list[str], start: int) -> int:
    """Index after the last line belonging to the item at `start`."""
    base = width(lines[start])
    end = start + 1
    last = start + 1
    while end < len(lines):
        line = lines[end]
        if line.strip():
            if width(line) <= base:
                break
            last = end + 1
        end += 1
    return last


def fully_ticked(lines: list[str], start: int, end: int) -> bool:
    return all(
        m.group(2).lower() == "x"
        for m in (TASK.match(l) for l in lines[start:end])
        if m
    )


def context_for(lines: list[str], start: int) -> list[str]:
    """Open ancestor items and the nearest heading above `start`."""
    chain: list[str] = []
    level = width(lines[start])
    heading = None
    for i in range(start - 1, -1, -1):
        line = lines[i]
        h = HEADING.match(line)
        if h:
            heading = h.group(2).strip().rstrip(":")
            break
        if not line.strip():
            continue
        w = width(line)
        if w < level:
            m = TASK.match(line) or BULLET.match(line)
            if m:
                text = m.groups()[-1]
                chain.append(DONE.sub("", re.sub(r"📅 \S+", "", text)).strip())
            level = w
    parts = ([heading] if heading else []) + list(reversed(chain))
    return [p for p in parts if p]


def sweep_board(board: Path, today: dt.date) -> tuple[list[str], list[tuple[dt.date, list[str]]]]:
    lines = board.read_text().splitlines()
    keep: list[str] = []
    moved: list[tuple[dt.date, list[str]]] = []
    i = 0
    while i < len(lines):
        m = TASK.match(lines[i])
        if m and m.group(2).lower() == "x":
            end = block_end(lines, i)
            if fully_ticked(lines, i, end):
                block = lines[i:end]
                done = DONE.search(block[0])
                when = dt.date.fromisoformat(done.group(1)) if done else today
                base = width(block[0])
                ctx = context_for(lines, i)
                head = block[0].expandtabs(4)[base:]
                if ctx:
                    head = head.replace("- [x] ", f"- [x] *{' › '.join(ctx)}* · ", 1)
                body = [l.expandtabs(4)[base:] if l.strip() else "" for l in block[1:]]
                moved.append((when, [head, *body]))
                i = end
                continue
        keep.append(lines[i])
        i += 1
    return keep, moved


def week_key(day: dt.date) -> tuple[int, int]:
    y, w, _ = day.isocalendar()
    return y, w


def week_heading(key: tuple[int, int]) -> str:
    monday = dt.date.fromisocalendar(key[0], key[1], 1)
    sunday = monday + dt.timedelta(days=6)
    return f"## {key[0]}-W{key[1]:02d} ({monday:%b %d} – {sunday:%b %d})"


def parse_log(text: str) -> tuple[list[str], dict[tuple[int, int], list[str]]]:
    head: list[str] = []
    weeks: dict[tuple[int, int], list[str]] = {}
    current = None
    for line in text.splitlines():
        m = WEEK.match(line)
        if m:
            current = (int(m.group(1)), int(m.group(2)))
            weeks.setdefault(current, [])
        elif current is None:
            head.append(line)
        else:
            weeks[current].append(line)
    return head, weeks


def new_log(project: str, today: dt.date) -> str:
    return (
        "---\n"
        f"date: {today}\n"
        f'description: "Dated log of completed {project} work: ticked tasks swept off the board and agent work records, by ISO week, newest first."\n'
        f"project: {project}\n"
        "status: active\n"
        "tags:\n"
        "  - work-note\n"
        "  - log\n"
        "---\n\n"
        f"# {project} Log\n\n"
        f"What got done on [[{project}]], by week. Ticked tasks move here from the board during standup or tidy (`log-sweep.py`); "
        "*italic prefixes* are the board section and open parent they sat under. 🤖 lines link agent work records.\n"
    )


def records_for(vault: Path, project: str) -> list[tuple[dt.date, str, str]]:
    found = []
    for folder in sorted((vault / "work" / "archive").glob(f"*/{project}")):
        for note in sorted(folder.glob("*.md")):
            m = RECORD.match(note.name)
            if not m:
                continue
            title = next(
                (l[2:].strip() for l in note.read_text().splitlines() if l.startswith("# ")),
                note.stem,
            )
            found.append((dt.date.fromisoformat(m.group(1)), note.stem, title))
    return found


def sweep_project(vault: Path, folder: Path, today: dt.date, apply: bool) -> list[str]:
    project = folder.name
    board = folder / f"{project}.md"
    if not board.is_file():
        return []
    log = folder / "Log.md"
    keep, moved = sweep_board(board, today)
    text = log.read_text() if log.exists() else new_log(project, today)
    head, weeks = parse_log(text)
    report = []
    for when, entry in moved:
        weeks.setdefault(week_key(when), []).extend(entry)
        report.append(f"  task  {when}  {entry[0][:100]}")
    for when, stem, title in records_for(vault, project):
        if f"[[{stem}" in text:
            continue
        weeks.setdefault(week_key(when), []).append(f"- 🤖 `{when}` [[{stem}|{title}]]")
        report.append(f"  record {when}  {stem}")
    if not report:
        return []
    out = "\n".join(head).rstrip("\n") + "\n"
    for key in sorted(weeks, reverse=True):
        body = "\n".join(weeks[key]).strip("\n")
        out += f"\n{week_heading(key)}\n\n{body}\n"
    if apply:
        log.write_text(out)
        board.write_text("\n".join(keep) + "\n")
    return [f"{project}: {len(moved)} task(s), {len(report) - len(moved)} record link(s) -> {log.relative_to(vault)}", *report]


def main() -> int:
    parser = argparse.ArgumentParser(description="Move ticked board tasks into each project's Log.md.")
    parser.add_argument("--apply", action="store_true", help="write changes (default: dry run)")
    parser.add_argument("--vault", type=Path, default=Path.cwd())
    parser.add_argument("--today", type=dt.date.fromisoformat, default=dt.date.today())
    args = parser.parse_args()
    active = args.vault / "work" / "active"
    if not active.is_dir():
        print(f"log-sweep: no work/active under {args.vault}", file=sys.stderr)
        return 1
    lines = []
    for folder in sorted(p for p in active.iterdir() if p.is_dir()):
        lines += sweep_project(args.vault, folder, args.today, args.apply)
    mode = "APPLIED" if args.apply else "DRY-RUN (pass --apply to write)"
    print(f"log-sweep — {mode}")
    print("\n".join(lines) if lines else "nothing to sweep.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
