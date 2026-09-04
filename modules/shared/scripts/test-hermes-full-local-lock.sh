#!/usr/bin/env bash

set -euo pipefail

repo_root="${1:-$(git rev-parse --show-toplevel)}"
repo_lock="$repo_root/modules/shared/config/skills/implement-tickets/scripts/with-repo-lock.py"
test_root="$(mktemp -d)"
trap 'rm -rf "$test_root"' EXIT

lock_repo="$test_root/repository"
lock_worktree="$test_root/worktree"
git init -q "$lock_repo"
git -C "$lock_repo" -c user.name=test -c user.email=test@example.invalid \
  commit --allow-empty -q -m initial
git -C "$lock_repo" worktree add -q -b lock-test "$lock_worktree"

lock_from_repo="$(HOME="$test_root/home" python3 "$repo_lock" --repo "$lock_repo" --print-path)"
lock_from_worktree="$(HOME="$test_root/home" python3 "$repo_lock" --repo "$lock_worktree" --print-path)"
[ "$lock_from_repo" = "$lock_from_worktree" ]

HOME="$test_root/home" python3 "$repo_lock" --repo "$lock_repo" --timeout 2 -- \
  sh -c 'printf first-start >> "$1"; sleep 0.4; printf first-end >> "$1"' sh "$test_root/order" &
first_lock_pid=$!
while [ ! -s "$lock_from_repo" ]; do sleep 0.01; done
HOME="$test_root/home" python3 "$repo_lock" --repo "$lock_worktree" --timeout 2 -- \
  sh -c 'printf second >> "$1"' sh "$test_root/order" &
second_lock_pid=$!
wait "$first_lock_pid"
wait "$second_lock_pid"
[ "$(cat "$test_root/order")" = 'first-startfirst-endsecond' ]

rm -f "$test_root/locked"
HOME="$test_root/home" python3 "$repo_lock" --repo "$lock_repo" --timeout 2 -- \
  sh -c 'touch "$1"; sleep 0.4' sh "$test_root/locked" &
first_lock_pid=$!
while [ ! -e "$test_root/locked" ]; do sleep 0.01; done
set +e
HOME="$test_root/home" python3 "$repo_lock" --repo "$lock_worktree" --timeout 0.05 -- true
timeout_status=$?
set -e
wait "$first_lock_pid"
[ "$timeout_status" -eq 75 ]

set +e
HOME="$test_root/home" python3 "$repo_lock" --repo "$lock_repo" --timeout 2 -- sh -c 'exit 23'
command_status=$?
set -e
[ "$command_status" -eq 23 ]

printf 'Hermes full-local repository lock: all checks passed\n'
