#!/usr/bin/env bash
# Iterate each src/<pkg>/ git repo in a Brazil workspace and print recent commits.
# Usage: ws-git-log.sh <workspace-root> <since> [extra git-log args...]
# Example: ws-git-log.sh ~/workplace/AMR "24 hours ago"

set -euo pipefail

workspace="${1:?workspace root required}"
since="${2:?since required (e.g. '24 hours ago')}"
shift 2

for dir in "$workspace"/src/*/; do
  [ -d "$dir/.git" ] || continue
  pkg=$(basename "$dir")
  (
    cd "$dir"
    git log --oneline --since="$since" --no-merges "$@" 2>/dev/null | sed "s|^|[$pkg] |"
  )
done
