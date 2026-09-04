#!/usr/bin/env bash

set -euo pipefail

repo_root="${1:-$(git rev-parse --show-toplevel)}"
integrator="$repo_root/modules/shared/config/skills/implement-tickets/scripts/integrate-reviewed.py"
test_root="$(mktemp -d)"
trap 'rm -rf "$test_root"' EXIT
export HOME="$test_root/home"
mkdir -p "$HOME"

new_repo() {
  local path="$1"
  git init -q -b main "$path"
  git -C "$path" config user.name test
  git -C "$path" config user.email test@example.invalid
  printf 'base\n' > "$path/file.txt"
  git -C "$path" add file.txt
  git -C "$path" commit -q -m base
}

make_candidate() {
  local path="$1"
  git -C "$path" switch -q -c candidate
  printf 'candidate\n' >> "$path/file.txt"
  git -C "$path" commit -qam candidate
  git -C "$path" rev-parse HEAD
  git -C "$path" switch -q main
}

success_repo="$test_root/success"
new_repo "$success_repo"
success_candidate="$(make_candidate "$success_repo")"
success_before="$(git -C "$success_repo" rev-parse main)"
success_evidence="$(python3 "$integrator" \
  --repo "$success_repo" \
  --candidate "$success_candidate" \
  --reviewed "$success_candidate" \
  --check 'grep -Fxq candidate file.txt' \
  --check 'git diff --check')"
success_after="$(git -C "$success_repo" rev-parse main)"
[ "$success_before" != "$success_after" ]
git -C "$success_repo" merge-base --is-ancestor "$success_candidate" main
python3 - "$success_evidence/transaction.json" <<'PY'
import json
import pathlib
import sys

transaction = json.loads(pathlib.Path(sys.argv[1]).read_text(encoding="utf-8"))
assert transaction["result"] == "integrated"
assert len(transaction["attempts"]) == 1
attempt_path = pathlib.Path(transaction["attempts"][0])
attempt = json.loads(attempt_path.read_text(encoding="utf-8"))
assert attempt["result"] == "integrated"
assert [check["exit_code"] for check in attempt["checks"]] == [0, 0]
assert pathlib.Path(attempt["worktree"]).is_dir()
PY

mismatch_repo="$test_root/mismatch"
new_repo "$mismatch_repo"
mismatch_candidate="$(make_candidate "$mismatch_repo")"
mismatch_before="$(git -C "$mismatch_repo" rev-parse main)"
set +e
python3 "$integrator" \
  --repo "$mismatch_repo" \
  --candidate "$mismatch_candidate" \
  --reviewed "$mismatch_before" \
  --check true >/dev/null 2>&1
mismatch_status=$?
set -e
[ "$mismatch_status" -ne 0 ]
[ "$(git -C "$mismatch_repo" rev-parse main)" = "$mismatch_before" ]

mutation_repo="$test_root/mutation"
new_repo "$mutation_repo"
mutation_candidate="$(make_candidate "$mutation_repo")"
mutation_before="$(git -C "$mutation_repo" rev-parse main)"
set +e
mutation_output="$(python3 "$integrator" \
  --repo "$mutation_repo" \
  --candidate "$mutation_candidate" \
  --reviewed "$mutation_candidate" \
  --check 'git commit --allow-empty -m unreviewed-check-commit' 2>/dev/null)"
mutation_status=$?
set -e
[ "$mutation_status" -ne 0 ]
[ "$(git -C "$mutation_repo" rev-parse main)" = "$mutation_before" ]
grep -Fq '"result": "check-mutated-head"' \
  "$(find "$mutation_output" -name evidence.json -print -quit)"

failure_repo="$test_root/failure"
new_repo "$failure_repo"
failure_candidate="$(make_candidate "$failure_repo")"
failure_before="$(git -C "$failure_repo" rev-parse main)"
set +e
failure_output="$(python3 "$integrator" \
  --repo "$failure_repo" \
  --candidate "$failure_candidate" \
  --reviewed "$failure_candidate" \
  --check 'printf failure-evidence; exit 42' 2>/dev/null)"
failure_status=$?
set -e
[ "$failure_status" -ne 0 ]
[ "$(git -C "$failure_repo" rev-parse main)" = "$failure_before" ]
failure_attempt="$(find "$failure_output" -name evidence.json -print -quit)"
python3 - "$failure_attempt" <<'PY'
import json
import pathlib
import sys

path = pathlib.Path(sys.argv[1])
attempt = json.loads(path.read_text(encoding="utf-8"))
assert attempt["result"] == "check-failed"
assert attempt["checks"][0]["exit_code"] == 42
assert pathlib.Path(attempt["checks"][0]["stdout"]).read_text(encoding="utf-8") == "failure-evidence"
assert pathlib.Path(attempt["worktree"]).is_dir()
PY
failure_branch_count="$(git -C "$failure_repo" for-each-ref --format='%(refname)' refs/heads/hermes/ | wc -l | tr -d ' ')"
[ "$failure_branch_count" -eq 1 ]

moved_repo="$test_root/moved"
new_repo "$moved_repo"
moved_candidate="$(make_candidate "$moved_repo")"
moved_marker="$test_root/moved-once"
moved_check="if [ ! -e '$moved_marker' ]; then touch '$moved_marker'; printf 'other\\n' > '$moved_repo/other.txt'; git -C '$moved_repo' add other.txt; git -C '$moved_repo' commit -q -m concurrent-move; fi"
moved_evidence="$(python3 "$integrator" \
  --repo "$moved_repo" \
  --candidate "$moved_candidate" \
  --reviewed "$moved_candidate" \
  --check "$moved_check")"
python3 - "$moved_evidence/transaction.json" <<'PY'
import json
import pathlib
import sys

transaction = json.loads(pathlib.Path(sys.argv[1]).read_text(encoding="utf-8"))
assert transaction["result"] == "integrated"
assert len(transaction["attempts"]) == 2
attempts = [
    json.loads(pathlib.Path(path).read_text(encoding="utf-8"))
    for path in transaction["attempts"]
]
assert [attempt["result"] for attempt in attempts] == ["target-moved", "integrated"]
PY
grep -Fxq candidate "$moved_repo/file.txt"
grep -Fxq other "$moved_repo/other.txt"

conflict_repo="$test_root/conflict"
new_repo "$conflict_repo"
git -C "$conflict_repo" switch -q -c candidate
printf 'candidate\n' > "$conflict_repo/file.txt"
git -C "$conflict_repo" commit -qam candidate
conflict_candidate="$(git -C "$conflict_repo" rev-parse HEAD)"
git -C "$conflict_repo" switch -q main
printf 'main\n' > "$conflict_repo/file.txt"
git -C "$conflict_repo" commit -qam main-change
conflict_before="$(git -C "$conflict_repo" rev-parse main)"
set +e
conflict_output="$(python3 "$integrator" \
  --repo "$conflict_repo" \
  --candidate "$conflict_candidate" \
  --reviewed "$conflict_candidate" \
  --check true 2>/dev/null)"
conflict_status=$?
set -e
[ "$conflict_status" -ne 0 ]
[ "$(git -C "$conflict_repo" rev-parse main)" = "$conflict_before" ]
grep -Fq '"result": "cherry-pick-conflict"' "$(find "$conflict_output" -name evidence.json -print -quit)"

dirty_repo="$test_root/dirty"
new_repo "$dirty_repo"
dirty_candidate="$(make_candidate "$dirty_repo")"
dirty_before="$(git -C "$dirty_repo" rev-parse main)"
printf 'untracked\n' > "$dirty_repo/untracked.txt"
set +e
python3 "$integrator" \
  --repo "$dirty_repo" \
  --candidate "$dirty_candidate" \
  --reviewed "$dirty_candidate" \
  --check true >/dev/null 2>&1
dirty_status=$?
set -e
[ "$dirty_status" -ne 0 ]
[ "$(git -C "$dirty_repo" rev-parse main)" = "$dirty_before" ]

printf 'Hermes full-local integration transaction: all checks passed\n'
