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

# Build context summary
echo "## Session Context"
echo ""
echo "### Date"
echo "$(date +%Y-%m-%d) ($(date +%A))"
echo ""

echo "### North Star (current goals)"
cat "$AI_DIR/brain/North Star.md" 2>/dev/null | head -30 || echo "(not found)"
echo ""

echo "### Recent Changes (last 48h)"
(cd "$VAULT_DIR" && git log --oneline --since="48 hours ago" --no-merges 2>/dev/null | head -15) || echo "(no git history)"
echo ""

echo "### Open Tasks (scheduled/due today, from vault markdown)"
TODAY="$(date +%Y-%m-%d)"
grep -rhE --include="*.md" "(📅|⏳) ${TODAY}" "$VAULT_DIR" 2>/dev/null \
  | grep -E "^\s*([-*]|[0-9]+\.) \[ \]" \
  | head -20 \
  || echo "(none)"
echo ""

echo "### Active Work"
ls "$AI_DIR"/work/active/*.md 2>/dev/null | sed "s|$AI_DIR/work/active/||;s|\.md$||" | head -10 || echo "(none)"
echo ""

echo "### Vault File Listing (AI/)"
find "$AI_DIR" -name "*.md" -not -path "*/thinking/*" -not -path "*/.claude/*" 2>/dev/null | sed "s|$VAULT_DIR/||" | sort
