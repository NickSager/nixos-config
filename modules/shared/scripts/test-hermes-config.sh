#!/usr/bin/env bash

set -euo pipefail

: "${HERMES_MANAGED_POLICY:?HERMES_MANAGED_POLICY must point to managed config.yaml}"
: "${YQ_BIN:?YQ_BIN must point to yq}"

[ "$($YQ_BIN '.approvals.mode' "$HERMES_MANAGED_POLICY")" = smart ]
[ "$($YQ_BIN '.approvals.cron_mode' "$HERMES_MANAGED_POLICY")" = deny ]
[ "$($YQ_BIN '.approvals.single_query_mode' "$HERMES_MANAGED_POLICY")" = approve ]
[ "$($YQ_BIN '.approvals.unattended_mode' "$HERMES_MANAGED_POLICY")" = deny ]
[ "$($YQ_BIN '.approvals.denial_breaker_threshold' "$HERMES_MANAGED_POLICY")" = 3 ]
[ "$($YQ_BIN '.approvals.deny | contains(["*git*push*", "*sudo*", "*terraform*apply*"])' "$HERMES_MANAGED_POLICY")" = true ]
[ "$($YQ_BIN '.delegation.subagent_auto_approve' "$HERMES_MANAGED_POLICY")" = true ]
[ "$($YQ_BIN '.delegation.worktree_isolation' "$HERMES_MANAGED_POLICY")" = true ]
[ "$($YQ_BIN 'has("model") or has("providers") or has("mcp_servers") or has("gateway")' "$HERMES_MANAGED_POLICY")" = false ]

if [ -n "${HERMES_BIN:-}" ]; then
  managed_dir="$(dirname "$HERMES_MANAGED_POLICY")"
  denied_commands=(
    'git push origin main'
    'git -C /tmp/repo push origin main'
    'git --git-dir=/tmp/repo/.git push origin main'
    'gh -R owner/repo pr create'
    'terraform -chdir=/tmp apply'
  )
  for command in "${denied_commands[@]}"; do
    set +e
    output="$(HERMES_MANAGED_DIR="$managed_dir" "$HERMES_BIN" approvals test "$command")"
    status=$?
    set -e
    [ "$status" -eq 3 ]
    grep -Fq 'verdict : user-deny' <<< "$output"
  done
  output="$(HERMES_MANAGED_DIR="$managed_dir" "$HERMES_BIN" approvals test 'git status')"
  grep -Fq 'verdict : allow' <<< "$output"
fi

printf 'hermes managed policy: all checks passed\n'
