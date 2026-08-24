#!/usr/bin/env python3
"""Mechanical slop / readability signals for a markdown prose document.

Usage: python3 check.py <file.md> [--max-words N]

Reports 4 signals — none is a verdict, all are prompts to look:
  - prose sentences over the word limit (default 20): candidates to split.
    A few list-style or procedure sentences over the limit are fine.
  - bold/italic emphasis outside code: house style uses markdown for
    structure, not emphasis; a nonzero count is worth a glance.
  - table column mismatches: a row whose pipe count differs from its header.
  - wikilink count: expected in a vault note; should read 0 in a doc
    that is going to be shared outside the vault.
"""
import re
import sys


def main():
    if len(sys.argv) < 2:
        print("usage: check.py <file.md> [--max-words N]")
        sys.exit(2)
    path = sys.argv[1]
    max_words = 20
    if "--max-words" in sys.argv:
        max_words = int(sys.argv[sys.argv.index("--max-words") + 1])

    text = open(path, encoding="utf-8").read()
    body = re.sub(r"^---\n.*?\n---\n", "", text, flags=re.S)  # strip frontmatter

    # Long prose sentences. Skip code, tables, headings; strip list markers,
    # links, wikilinks, and inline code so they do not inflate the word count.
    long_sents = []
    in_code = False
    for line in body.splitlines():
        s = line.strip()
        if s.startswith("```"):
            in_code = not in_code
            continue
        if in_code or not s or s.startswith("|") or s.startswith("#"):
            continue
        t = re.sub(r"^[-*\d.]+\s*", "", s)
        t = re.sub(r"\[\[([^\]|]+\|)?([^\]]+)\]\]", r"\2", t)
        t = re.sub(r"\[([^\]]+)\]\([^)]+\)", r"\1", t)
        t = re.sub(r"`[^`]*`", "X", t)
        for sent in re.split(r"(?<=[.!?])\s+", t):
            n = len(sent.split())
            if n > max_words:
                long_sents.append((n, sent[:90]))

    # Emphasis outside code. Strip fenced blocks and inline code first, so a
    # stray asterisk inside a code span (e.g. '.*') is not a false positive.
    no_code = re.sub(r"```.*?```", "", body, flags=re.S)
    no_code = re.sub(r"`[^`]*`", "", no_code)
    emph = re.findall(r"\*\*[^*]+\*\*|(?<![\w*])\*[^*\s][^*]*\*(?![\w*])", no_code)

    # Table column consistency.
    tables = 0
    bad_rows = 0
    cols = None
    prev_pipe = False
    for line in body.splitlines():
        stripped = line.strip()
        if stripped.startswith("|"):
            n = stripped.count("|")
            if not prev_pipe:
                tables += 1
                cols = n
            elif n != cols and not set(stripped) <= set("|-: "):
                bad_rows += 1
            prev_pipe = True
        else:
            prev_pipe = False
            cols = None

    wikilinks = len(re.findall(r"\[\[", body))

    print(f"PROSE SENTENCES >{max_words} WORDS: {len(long_sents)}")
    for n, s in long_sents:
        print(f"  [{n}] {s}")
    print(f"EMPHASIS (bold/italic outside code): {len(emph)} {emph[:5]}")
    print(f"TABLES: {tables}  BAD ROWS: {bad_rows}")
    print(f"WIKILINKS: {wikilinks}")


if __name__ == "__main__":
    main()
