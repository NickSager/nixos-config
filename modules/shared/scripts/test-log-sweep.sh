#!/usr/bin/env bash
# Fixture test for config/obsidian-mind/log-sweep.py.

set -euo pipefail

script="$(cd "$(dirname "$0")/../config/obsidian-mind" && pwd)/log-sweep.py"
root="$(mktemp -d)"
trap 'rm -r "$root"' EXIT
board="$root/work/active/Demo/Demo.md"
mkdir -p "$(dirname "$board")" "$root/work/archive/2026/Demo"

printf '%s\n' \
  '# Demo' '' '## Tracker' '' \
  '- [x] Solo done ✅ 2026-10-02' \
  '- [ ] Open parent' \
  $'\t- [x] Child done ✅ 2026-10-05' \
  $'\t\t- note under child' \
  $'\t- [ ] Child open' \
  '- [x] Done parent with open child ✅ 2026-10-01' \
  $'\t- [ ] still open' \
  > "$board"
printf '# Agent did a thing\n' > "$root/work/archive/2026/Demo/2026-09-30-agent-did-a-thing.md"

python3 "$script" --vault "$root" --today 2026-10-06 | grep -q 'DRY-RUN'
[ ! -e "$root/work/active/Demo/Log.md" ]

python3 "$script" --vault "$root" --today 2026-10-06 --apply >/dev/null
log="$root/work/active/Demo/Log.md"

grep -q '^- \[ \] Open parent$' "$board"
grep -q $'^\t- \\[ \\] Child open$' "$board"
grep -q '^- \[x\] Done parent with open child' "$board"
if grep -q 'Solo done\|Child done' "$board"; then exit 1; fi

grep -q '^- \[x\] \*Tracker\* · Solo done ✅ 2026-10-02$' "$log"
grep -q '^- \[x\] \*Tracker › Open parent\* · Child done ✅ 2026-10-05$' "$log"
grep -q '^    - note under child$' "$log"
# shellcheck disable=SC2016 # backticks are literal Markdown
grep -q '^- 🤖 `2026-09-30` \[\[2026-09-30-agent-did-a-thing|Agent did a thing\]\]$' "$log"
# Newest week first: W41 (Child done) above W40 (Solo done, record).
[ "$(grep -n '^## 2026-W41' "$log" | cut -d: -f1)" -lt "$(grep -n '^## 2026-W40' "$log" | cut -d: -f1)" ]

before="$(cat "$log" "$board")"
python3 "$script" --vault "$root" --today 2026-10-06 --apply | grep -q 'nothing to sweep'
[ "$before" = "$(cat "$log" "$board")" ]

echo "log-sweep: all checks passed"
