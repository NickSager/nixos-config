#!/usr/bin/env bash

set -euo pipefail

die() {
  printf 'mind-agent-integration: %s\n' "$*" >&2
  exit 1
}

require_safe_relative_path() {
  case "$1" in
    ''|/*|..|../*|*/..|*/../*) die "refusing unsafe managed path: $1" ;;
  esac
}

replace_block() {
  local target="$1"
  local start="$2"
  local end="$3"
  local content="$4"
  local tmp

  mkdir -p "$(dirname "$target")"
  touch "$target"
  tmp="$(mktemp "${target}.tmp.XXXXXX")"
  awk -v start="$start" -v end="$end" '
    $0 == start { skipping = 1; next }
    skipping && $0 == end { skipping = 0; next }
    !skipping {
      lines[++count] = $0
      if ($0 !~ /^[[:space:]]*$/) last = count
    }
    END {
      for (i = 1; i <= last; i++) print lines[i]
    }
  ' "$target" > "$tmp"
  if [ -s "$tmp" ]; then
    printf '\n' >> "$tmp"
  fi
  printf '%s\n' "$start" >> "$tmp"
  cat "$content" >> "$tmp"
  printf '\n%s\n' "$end" >> "$tmp"
  chmod --reference="$target" "$tmp" 2>/dev/null || chmod 644 "$tmp"
  mv "$tmp" "$target"
}

remove_previous_skill_exports() {
  local mind_dir="$1"
  local manifest="$mind_dir/.obsidian-mind-om-skill-files"
  local rel

  [ -f "$manifest" ] || return 0
  while IFS= read -r rel; do
    [ -n "$rel" ] || continue
    require_safe_relative_path "$rel"
    case "$rel" in
      .agents/skills/om-*/SKILL.md) rm -f "$mind_dir/$rel" ;;
      *) die "refusing unexpected OM skill path in manifest: $rel" ;;
    esac
  done < "$manifest"
}

export_skills() {
  local mind_dir="$1"
  local commands="$mind_dir/.claude/commands"
  local manifest="$mind_dir/.obsidian-mind-om-skill-files"
  local stage_manifest="$mind_dir/.obsidian-mind-stage-paths"
  local next_manifest
  local command name skill_dir description

  [ -d "$commands" ] || die "missing upstream command directory: $commands"
  next_manifest="$(mktemp "${manifest}.tmp.XXXXXX")"
  if [ -f "$manifest" ]; then
    cat "$manifest" >> "$stage_manifest"
  fi
  remove_previous_skill_exports "$mind_dir"

  for command in "$commands"/om-*.md; do
    [ -f "$command" ] || continue
    name="$(basename "$command" .md)"
    skill_dir="$mind_dir/.agents/skills/$name"
    description="$(awk '
      NR == 1 && $0 == "---" { frontmatter = 1; next }
      frontmatter && /^description:[[:space:]]*/ { print; exit }
      frontmatter && $0 == "---" { exit }
    ' "$command")"
    [ -n "$description" ] || description="description: Run the upstream $name workflow from obsidian-mind."
    mkdir -p "$skill_dir"
    {
      printf '%s\n' '---' "name: $name" "$description" '---' ''
      if grep -q 'SessionStart' "$command"; then
        printf '%s\n' \
          '## Cross-agent context' \
          '' \
          'References to SessionStart context are conditional. If the current session does not already contain that context, run the following command from the Mind vault root and use its output as the missing injection:' \
          '' \
          '```bash' \
          'CLAUDE_PROJECT_DIR="$PWD" node --experimental-strip-types .claude/scripts/session-start.ts </dev/null' \
          '```' \
          ''
      fi
      awk '
        NR == 1 && $0 == "---" { frontmatter = 1; next }
        frontmatter && $0 == "---" { frontmatter = 0; next }
        !frontmatter { print }
      ' "$command"
    } > "$skill_dir/SKILL.md"
    printf '.agents/skills/%s/SKILL.md\n' "$name" >> "$next_manifest"
  done

  [ -s "$next_manifest" ] || die "no om-* commands were exported"
  sort -u "$next_manifest" -o "$next_manifest"
  install -m644 "$next_manifest" "$manifest"
  cat "$next_manifest" >> "$stage_manifest"
  printf '.obsidian-mind-om-skill-files\n' >> "$stage_manifest"
  rm -f "$next_manifest"
}

configure_instructions() {
  local mind_dir="$1"
  local global_content="$2"
  local hermes_content="$3"

  replace_block \
    "$mind_dir/brain/CLAUDE-global.md" \
    '<!-- NIX-MANAGED: OM PROJECT RECORDING START -->' \
    '<!-- NIX-MANAGED: OM PROJECT RECORDING END -->' \
    "$global_content"
  replace_block \
    "$HOME/.hermes/SOUL.md" \
    '<!-- NIX-MANAGED: OM PROJECT RECORDING START -->' \
    '<!-- NIX-MANAGED: OM PROJECT RECORDING END -->' \
    "$hermes_content"
}

configure_codex() {
  local wrapper="$1"
  local config="$HOME/.codex/config.toml"
  local stripped

  mkdir -p "$(dirname "$config")"
  touch "$config"
  stripped="$(mktemp "${config}.tmp.XXXXXX")"
  awk '
    $0 == "# NIX-MANAGED OM MCP START" { managed = 1; next }
    managed && $0 == "# NIX-MANAGED OM MCP END" { managed = 0; next }
    managed { next }
    $0 == "[mcp_servers.om]" { legacy = 1; next }
    legacy && /^\[/ { legacy = 0 }
    !legacy {
      lines[++count] = $0
      if ($0 !~ /^[[:space:]]*$/) last = count
    }
    END {
      for (i = 1; i <= last; i++) print lines[i]
    }
  ' "$config" > "$stripped"
  if [ -s "$stripped" ]; then
    printf '\n' >> "$stripped"
  fi
  printf '%s\n%s\n%s\n%s\n%s\n' \
    '# NIX-MANAGED OM MCP START' \
    '[mcp_servers.om]' \
    "command = \"$wrapper\"" \
    'args = []' \
    '# NIX-MANAGED OM MCP END' >> "$stripped"
  chmod --reference="$config" "$stripped" 2>/dev/null || chmod 600 "$stripped"
  mv "$stripped" "$config"
}

configure_claude() {
  local wrapper="$1"
  local config="$HOME/.claude.json"
  local tmp

  mkdir -p "$(dirname "$config")"
  if [ ! -s "$config" ]; then
    printf '{}\n' > "$config"
  elif ! "$JQ_BIN" empty "$config" >/dev/null 2>&1; then
    die "refusing to replace invalid JSON in $config"
  fi
  tmp="$(mktemp "${config}.tmp.XXXXXX")"
  "$JQ_BIN" --arg wrapper "$wrapper" \
    '.mcpServers.om = {type: "stdio", command: $wrapper, args: [], env: {}}' \
    "$config" > "$tmp"
  chmod --reference="$config" "$tmp" 2>/dev/null || chmod 600 "$tmp"
  mv "$tmp" "$config"
}

configure_hermes() {
  local wrapper="$1"
  local skills_dir="$2"
  local config="$HOME/.hermes/config.yaml"
  local tmp

  mkdir -p "$(dirname "$config")"
  [ -s "$config" ] || printf '{}\n' > "$config"
  tmp="$(mktemp "${config}.tmp.XXXXXX")"
  OM_WRAPPER="$wrapper" MIND_SKILLS="$skills_dir" "$YQ_BIN" eval '
    .skills.external_dirs = ((.skills.external_dirs // []) + [strenv(MIND_SKILLS)] | unique) |
    .mcp_servers.om = {
      "command": strenv(OM_WRAPPER),
      "args": []
    }
  ' "$config" > "$tmp"
  chmod --reference="$config" "$tmp" 2>/dev/null || chmod 600 "$tmp"
  mv "$tmp" "$config"
}

configure_clients() {
  local mind_dir="$1"
  local wrapper="$2"

  : "${JQ_BIN:?JQ_BIN must point to jq}"
  : "${YQ_BIN:?YQ_BIN must point to yq}"
  configure_codex "$wrapper"
  configure_claude "$wrapper"
  configure_hermes "$wrapper" "$mind_dir/.agents/skills"
}

git_sync() {
  local mind_dir="$1"
  local revision="$2"
  local stage_manifest="$mind_dir/.obsidian-mind-stage-paths"
  local marker="$mind_dir/.obsidian-mind-revision"
  local short_revision="${revision:0:12}"
  local initial=0
  local rel
  local -a paths=()

  printf '%s\n' "$revision" > "$marker"
  printf '.obsidian-mind-revision\n' >> "$stage_manifest"

  if [ ! -d "$mind_dir/.git" ]; then
    git -C "$mind_dir" init -b main >/dev/null
    initial=1
  fi
  git -C "$mind_dir" config user.name >/dev/null 2>&1 || \
    git -C "$mind_dir" config user.name 'Nix obsidian-mind updater'
  git -C "$mind_dir" config user.email >/dev/null 2>&1 || \
    git -C "$mind_dir" config user.email 'obsidian-mind@nix.local'

  sort -u "$stage_manifest" -o "$stage_manifest"
  while IFS= read -r rel; do
    [ -n "$rel" ] || continue
    require_safe_relative_path "$rel"
    paths+=("$rel")
    git -C "$mind_dir" add -A -- "$rel"
  done < "$stage_manifest"

  if ! git -C "$mind_dir" diff --cached --quiet -- "${paths[@]}"; then
    if [ "$initial" -eq 1 ]; then
      git -C "$mind_dir" commit -m "Initialize obsidian-mind at $short_revision" -- "${paths[@]}" >/dev/null
    else
      git -C "$mind_dir" commit -m "Update obsidian-mind to $short_revision" -- "${paths[@]}" >/dev/null
    fi
  fi
  rm -f "$stage_manifest"
}

case "${1:-}" in
  export-skills)
    [ "$#" -eq 2 ] || die 'usage: export-skills MIND_DIR'
    export_skills "$2"
    ;;
  configure-instructions)
    [ "$#" -eq 4 ] || die 'usage: configure-instructions MIND_DIR GLOBAL_CONTENT HERMES_CONTENT'
    configure_instructions "$2" "$3" "$4"
    ;;
  configure-clients)
    [ "$#" -eq 3 ] || die 'usage: configure-clients MIND_DIR WRAPPER'
    configure_clients "$2" "$3"
    ;;
  git-sync)
    [ "$#" -eq 3 ] || die 'usage: git-sync MIND_DIR REVISION'
    git_sync "$2" "$3"
    ;;
  *)
    die 'expected export-skills, configure-instructions, configure-clients, or git-sync'
    ;;
esac
