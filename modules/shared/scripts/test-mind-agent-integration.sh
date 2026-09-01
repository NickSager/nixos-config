#!/usr/bin/env bash

set -euo pipefail

: "${MIND_SOURCE:?MIND_SOURCE must point to an obsidian-mind tree}"
: "${JQ_BIN:?JQ_BIN must point to jq}"
: "${YQ_BIN:?YQ_BIN must point to yq}"

script_dir="$(cd "$(dirname "$0")" && pwd)"
integration="$script_dir/mind-agent-integration.sh"
config_dir="$script_dir/../config/obsidian-mind"
test_root="$(mktemp -d)"
trap 'rm -rf "$test_root"' EXIT

export HOME="$test_root/home"
mind="$HOME/Documents/Notes"
mkdir -p "$mind/.claude" "$mind/brain" "$HOME/.codex" "$HOME/.hermes"
cp -R "$MIND_SOURCE/.claude/commands" "$mind/.claude/commands"
chmod -R u+w "$mind/.claude/commands"
printf '# Personal instructions\n' > "$mind/brain/CLAUDE-global.md"
printf '# Personal soul\n' > "$HOME/.hermes/SOUL.md"
cat > "$HOME/.codex/config.toml" <<'EOF'
model = "test"

[mcp_servers.om]
command = "old"
args = ["old"]

[mcp_servers.keep]
command = "keep"
EOF
printf '{"preserved":true}\n' > "$HOME/.claude.json"
cat > "$HOME/.hermes/config.yaml" <<'EOF'
skills:
  external_dirs:
    - /keep/skills
model:
  default: test
EOF

snapshot="$test_root/first-run.cksum"
for round in 1 2; do
  bash "$integration" export-skills "$mind"
  bash "$integration" configure-instructions \
    "$mind" "$config_dir/global-instructions.md" "$config_dir/hermes-soul.md"
  bash "$integration" configure-clients "$mind" "$HOME/.local/bin/om-mcp"
  {
    cksum "$mind/brain/CLAUDE-global.md"
    cksum "$HOME/.hermes/SOUL.md"
    cksum "$HOME/.codex/config.toml"
    cksum "$HOME/.claude.json"
    cksum "$HOME/.hermes/config.yaml"
    find "$mind/.agents/skills" -type f -name SKILL.md -exec cksum {} \; | sort
  } > "$test_root/current.cksum"
  if [ "$round" -eq 1 ]; then
    cp "$test_root/current.cksum" "$snapshot"
  else
    cmp "$snapshot" "$test_root/current.cksum"
  fi
done

expected="$(find "$MIND_SOURCE/.claude/commands" -maxdepth 1 -name 'om-*.md' | wc -l | tr -d ' ')"
actual="$(find "$mind/.agents/skills" -mindepth 2 -maxdepth 2 -name SKILL.md | wc -l | tr -d ' ')"
[ "$actual" = "$expected" ]
grep -q '^## Cross-agent context$' "$mind/.agents/skills/om-standup/SKILL.md"
grep -q '^description: "Morning kickoff' "$mind/.agents/skills/om-standup/SKILL.md"
[ "$(grep -c 'NIX-MANAGED: OM PROJECT RECORDING START' "$mind/brain/CLAUDE-global.md")" = 1 ]
[ "$(grep -c 'NIX-MANAGED: OM PROJECT RECORDING START' "$HOME/.hermes/SOUL.md")" = 1 ]
[ "$(grep -c '^\[mcp_servers.om\]$' "$HOME/.codex/config.toml")" = 1 ]
grep -q '^\[mcp_servers.keep\]$' "$HOME/.codex/config.toml"
"$JQ_BIN" -e '.preserved == true and .mcpServers.om.command == $wrapper' \
  --arg wrapper "$HOME/.local/bin/om-mcp" "$HOME/.claude.json" >/dev/null
[ "$("$YQ_BIN" '.model.default' "$HOME/.hermes/config.yaml")" = test ]
[ "$("$YQ_BIN" '.mcp_servers.om.command' "$HOME/.hermes/config.yaml")" = "$HOME/.local/bin/om-mcp" ]
grep -q -- '- /keep/skills' "$HOME/.hermes/config.yaml"
grep -q -- "- $mind/.agents/skills" "$HOME/.hermes/config.yaml"

printf '.claude/commands/om-standup.md\n.obsidian-mind-managed-files\n' \
  > "$mind/.obsidian-mind-managed-files"
printf '.claude/commands/om-standup.md\n.obsidian-mind-managed-files\n' \
  >> "$mind/.obsidian-mind-stage-paths"
printf 'user content\n' > "$mind/brain/user.md"
bash "$integration" git-sync "$mind" 1111111111111111111111111111111111111111
git -C "$mind" show --name-only --format= HEAD | grep -q '^.claude/commands/om-standup.md$'
if git -C "$mind" show --name-only --format= HEAD | grep -q '^brain/user.md$'; then
  printf 'initial managed commit captured user content\n' >&2
  exit 1
fi
first_commit_count="$(git -C "$mind" rev-list --count HEAD)"
printf '.claude/commands/om-standup.md\n.obsidian-mind-managed-files\n' \
  > "$mind/.obsidian-mind-stage-paths"
bash "$integration" git-sync "$mind" 1111111111111111111111111111111111111111
[ "$(git -C "$mind" rev-list --count HEAD)" = "$first_commit_count" ]

git -C "$mind" add brain/user.md
printf '\nmanaged update\n' >> "$mind/.claude/commands/om-standup.md"
printf '.claude/commands/om-standup.md\n.obsidian-mind-managed-files\n' \
  > "$mind/.obsidian-mind-stage-paths"
bash "$integration" git-sync "$mind" 2222222222222222222222222222222222222222
git -C "$mind" diff --cached --name-only | grep -q '^brain/user.md$'
if git -C "$mind" show --name-only --format= HEAD | grep -q '^brain/user.md$'; then
  printf 'managed update commit captured staged user content\n' >&2
  exit 1
fi

printf 'mind-agent-integration: all checks passed (%s exported skills)\n' "$actual"
