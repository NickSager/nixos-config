#!/bin/bash
set -eo pipefail

# Resolve vault path — always use the Obsidian vault, regardless of cwd
VAULT_DIR="$HOME/Documents/Notes"
AI_DIR="$VAULT_DIR/AI"

# Persist vault path for the session
if [ -n "${CLAUDE_ENV_FILE:-}" ]; then
  echo "export VAULT_PATH=\"$VAULT_DIR\"" >> "$CLAUDE_ENV_FILE"
fi

# Incremental QMD re-index (fast, non-blocking if qmd not installed)
(cd "$VAULT_DIR" && qmd update 2>/dev/null) || true

# Helper: run a command with a timeout, fall back to alternative
run_with_timeout() {
  local timeout_sec=$1; shift
  local fallback_cmd=$1; shift
  if command -v gtimeout &>/dev/null; then
    gtimeout "$timeout_sec" "$@" 2>/dev/null || eval "$fallback_cmd"
  elif command -v timeout &>/dev/null; then
    timeout "$timeout_sec" "$@" 2>/dev/null || eval "$fallback_cmd"
  else
    "$@" 2>/dev/null || eval "$fallback_cmd"
  fi
}

# Build context summary
echo "## Session Context"
echo ""
echo "### Date"
echo "$(date +%Y-%m-%d) ($(date +%A))"
echo ""

echo "### North Star (current goals)"
if command -v obsidian &>/dev/null; then
  run_with_timeout 5 "cat '$AI_DIR/brain/North Star.md' 2>/dev/null | head -30" obsidian read file="North Star" | head -30
else
  cat "$AI_DIR/brain/North Star.md" 2>/dev/null | head -30 || echo "(not found)"
fi
echo ""

echo "### Recent Changes (last 48h)"
(cd "$VAULT_DIR" && git log --oneline --since="48 hours ago" --no-merges 2>/dev/null | head -15) || echo "(no git history)"
echo ""

echo "### Open Tasks"
if command -v obsidian &>/dev/null; then
  run_with_timeout 5 'echo "(CLI timed out)"' obsidian tasks daily todo | head -10
else
  echo "(Obsidian CLI not available)"
fi
echo ""

echo "### Active Work"
ls "$AI_DIR"/work/active/*.md 2>/dev/null | sed "s|$AI_DIR/work/active/||;s|\.md$||" | head -10 || echo "(none)"
echo ""

echo "### Vault File Listing (AI/)"
find "$AI_DIR" -name "*.md" -not -path "*/thinking/*" -not -path "*/.claude/*" 2>/dev/null | sed "s|$VAULT_DIR/||" | sort
