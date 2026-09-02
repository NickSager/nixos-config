# One Obsidian and agent vault at ~/Documents/Notes. Pinned obsidian-mind
# machinery and explicit Obsidian configuration are copied as real files.
# User-created notes and Obsidian workspace state remain user-owned. Pinned
# upstream entrypoints and documentation listed in the manifest stay managed.

{ config, lib, pkgs, profile ? "personal", obsidian-mind ? null, ... }:

let
  obsidianSource = ./config/obsidian;
  obsidianPlugins = import ./obsidian-plugins.nix { inherit pkgs; };
  vaultDir = "Documents/Notes";
  mindRevision = if obsidian-mind == null then "unknown" else obsidian-mind.rev or "unknown";
  mindIntegration = pkgs.callPackage ./mind-agent-integration.nix { };
  omGlobalInstructions = ./config/obsidian-mind/global-instructions.md;
  omHermesInstructions = ./config/obsidian-mind/hermes-soul.md;
  omWrapUpAddon = ./config/obsidian-mind/wrap-up-addon.md;
  omMcpWrapper = pkgs.writeShellScript "om-mcp" ''
    project_root="$PWD"
    if [ -n "''${OM_PROJECT_ROOT:-}" ]; then
      project_root="$OM_PROJECT_ROOT"
    fi
    caller="$(basename "$project_root" | tr '[:upper:]' '[:lower:]' | tr -cd '[:alnum:]_.-')"
    if [ -f "$project_root/.om-project" ]; then
      declared="$(sed -n '/^[[:space:]]*#/d; /^[[:space:]]*$/d; { s/^[[:space:]]*//; s/[[:space:]]*$//; p; q; }' "$project_root/.om-project")"
      if [ -n "$declared" ]; then
        case "$declared" in
          *[!A-Za-z0-9_.-]*) ;;
          *) caller="$(printf '%s' "$declared" | tr '[:upper:]' '[:lower:]')" ;;
        esac
      fi
    fi
    if [ -n "$caller" ]; then
      export OM_CALLER="$caller"
    fi
    exec ${pkgs.nodejs}/bin/node "$HOME/Documents/Notes/.claude/scripts/om-mcp.mjs"
  '';

  json = pkgs.formats.json { };
  hotkeysJson = json.generate "hotkeys.json" {
    "file-explorer:new-file" = [];
    "daily-notes" = [{ modifiers = ["Mod"]; key = "D"; }];
    "templater-obsidian:create-new-note-from-template" = [{ modifiers = ["Mod"]; key = "N"; }];
  };
  appJson = json.generate "app.json" {
    userIgnoreFilters = [
      "ARCHITECTURE.md" "README.md" "README.ja.md" "README.ko.md"
      "README.zh-CN.md" "CHANGELOG.md" "CONTRIBUTING.md" ".agents/"
      ".claude/" ".scripts/" ".claude-plugin/" ".codex/" ".gemini/"
      ".shardmind/"
    ];
  };
  appearanceJson = json.generate "appearance.json" { cssTheme = "Soft Paper"; };
  corePluginsJson = json.generate "core-plugins.json" {
    daily-notes = true;
    templates = true;
    backlink = true;
    global-search = true;
    graph = true;
    outline = true;
    tag-pane = true;
    file-explorer = true;
    command-palette = true;
    bookmarks = true;
    editor-status = true;
    word-count = true;
    bases = true;
  };
  dailyNotesJson = json.generate "daily-notes.json" {
    folder = "";
    format = "YYYY-MM-DD";
    template = "";
  };
  templatesJson = json.generate "templates.json" { folder = "templates"; };
  communityPluginList = with obsidianPlugins; [
    obsidian-tasks-plugin dataview templater-obsidian nldates-obsidian vim-yank-highlight
  ];
  communityPluginsJson = json.generate "community-plugins.json"
    (map (plugin: plugin.manifestId) communityPluginList);
  templaterJson = json.generate "templater-data.json" {
    command_timeout = 5;
    templates_folder = "templates";
    templates_pairs = [["" ""]];
    trigger_on_file_creation = false;
    auto_jump_to_cursor = true;
    enable_system_commands = false;
    shell_path = "";
    user_scripts_folder = "";
    enable_folder_templates = false;
    folder_templates = [];
    enable_file_templates = false;
    file_templates = [{ regex = ".*"; template = ""; }];
    syntax_highlighting = true;
    syntax_highlighting_mobile = false;
    enabled_templates_hotkeys = [""];
    startup_templates = [""];
    intellisense_render = 1;
  };
in

{
  programs.obsidian = {
    enable = true;
    # Register the vault and install Obsidian. The activation below copies
    # vault configuration as writable real files instead of Home Manager links.
    vaults.${vaultDir} = { };
  };

  home.file = {
    ".local/bin/om-mcp" = {
      source = omMcpWrapper;
      executable = true;
    };
  };

  home.activation = lib.optionalAttrs (obsidian-mind != null) {
    # Pinned obsidian-mind and writable Obsidian configuration share one vault.
    # Upstream obsidian-mind lands here from the pinned flake input.
    # An upgrade is: bump the tag in flake.nix, `nix flake update
    # obsidian-mind`, read the upstream CHANGELOG, rebuild.
    agentVault = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      MIND_DIR="$HOME/Documents/Notes"
      mkdir -p "$MIND_DIR/memories"

      MANAGED_MANIFEST="$MIND_DIR/.obsidian-mind-managed-files"
      STAGE_MANIFEST="$MIND_DIR/.obsidian-mind-stage-paths"
      NEXT_MANIFEST="$(mktemp "$MIND_DIR/.obsidian-mind-managed-files.tmp.XXXXXX")"
      [ ! -f "$MANAGED_MANIFEST" ] || cat "$MANAGED_MANIFEST" >> "$STAGE_MANIFEST"

      # Machinery: changed upstream files are replaced when a release-tag
      # bump lands, while unchanged files and custom siblings are untouched.
      # A new upstream top-level directory needs one entry here.
      for dir in .claude/agents .claude/commands .claude/scripts .claude/skills \
                 .claude-plugin .codex .gemini .scripts .shardmind bases templates; do
        mkdir -p "$MIND_DIR/$dir"
        ${mindIntegration}/bin/mind-agent-integration sync-tree-if-changed \
          ${obsidian-mind}/$dir "$MIND_DIR/$dir"
        find ${obsidian-mind}/$dir \( -type f -o -type l \) -print | \
          sed "s#^${obsidian-mind}/##" >> "$NEXT_MANIFEST"
      done
      for f in .claude/memory-template.md .claude/update-skills.ts .mcp.json \
               .shardmindignore AGENTS.md CLAUDE.md GEMINI.md Home.md vault-manifest.json; do
        ${mindIntegration}/bin/mind-agent-integration install-if-changed \
          ${obsidian-mind}/$f "$MIND_DIR/$f"
        printf '%s\n' "$f" >> "$NEXT_MANIFEST"
      done

      WRAP_UP_WITH_ADDON="$(mktemp)"
      cat ${obsidian-mind}/.claude/commands/om-wrap-up.md ${omWrapUpAddon} \
        > "$WRAP_UP_WITH_ADDON"
      ${mindIntegration}/bin/mind-agent-integration install-if-changed \
        "$WRAP_UP_WITH_ADDON" "$MIND_DIR/.claude/commands/om-wrap-up.md"
      rm -f "$WRAP_UP_WITH_ADDON"
      sort -u "$NEXT_MANIFEST" -o "$NEXT_MANIFEST"
      if [ -f "$MANAGED_MANIFEST" ]; then
        while IFS= read -r rel; do
          [ -n "$rel" ] || continue
          grep -Fqx "$rel" "$NEXT_MANIFEST" && continue
          ${mindIntegration}/bin/mind-agent-integration validate-managed-path \
            "$MIND_DIR" "$rel"
          case "$rel" in
            .claude/agents/*|.claude/commands/*|.claude/scripts/*|.claude/skills/*|\
            .claude-plugin/*|.codex/*|.gemini/*|.scripts/*|.shardmind/*|bases/*|templates/*|\
            .claude/memory-template.md|.claude/update-skills.ts|.mcp.json|.shardmindignore|\
            AGENTS.md|CLAUDE.md|GEMINI.md|Home.md|vault-manifest.json)
              rm -f "$MIND_DIR/$rel"
              ;;
            *)
              echo "Refusing unexpected stale Mind path: $rel" >&2
              exit 1
              ;;
          esac
        done < "$MANAGED_MANIFEST"
      fi
      ${mindIntegration}/bin/mind-agent-integration install-if-changed \
        "$NEXT_MANIFEST" "$MANAGED_MANIFEST"
      cat "$NEXT_MANIFEST" >> "$STAGE_MANIFEST"
      printf '%s\n' '.obsidian-mind-managed-files' >> "$STAGE_MANIFEST"
      rm -f "$NEXT_MANIFEST"

      # Content: seeded once, never overwritten. User-created notes and
      # Obsidian state stay user-owned. Pinned upstream entrypoints and docs
      # listed above stay managed. cp -Rn adds files a new release ships
      # without touching existing ones. .claude/settings.json is deliberately
      # not copied here; the settings split owns it.
      for dir in .obsidian brain org perf reference thinking work; do
        mkdir -p "$MIND_DIR/$dir"
        cp -Rn ${obsidian-mind}/$dir/. "$MIND_DIR/$dir/" 2>/dev/null || true
      done

      # Store copies arrive read-only; the vault must stay editable.
      chmod -R u+w "$MIND_DIR"

      # Copy an explicit Obsidian file set. Only paths recorded in this
      # manifest can be replaced or removed; workspace and other user state
      # are never included.
      OBSIDIAN_MANIFEST="$MIND_DIR/.nix-managed-obsidian-files"
      NEXT_OBSIDIAN_MANIFEST="$(mktemp "$MIND_DIR/.nix-managed-obsidian-files.tmp.XXXXXX")"
      [ ! -f "$OBSIDIAN_MANIFEST" ] || cat "$OBSIDIAN_MANIFEST" >> "$STAGE_MANIFEST"

      mkdir -p "$MIND_DIR/.obsidian/plugins" "$MIND_DIR/.obsidian/themes"
      ${mindIntegration}/bin/mind-agent-integration install-if-changed ${appJson} "$MIND_DIR/.obsidian/app.json"
      ${mindIntegration}/bin/mind-agent-integration install-if-changed ${appearanceJson} "$MIND_DIR/.obsidian/appearance.json"
      ${mindIntegration}/bin/mind-agent-integration install-if-changed ${corePluginsJson} "$MIND_DIR/.obsidian/core-plugins.json"
      ${mindIntegration}/bin/mind-agent-integration install-if-changed ${dailyNotesJson} "$MIND_DIR/.obsidian/daily-notes.json"
      ${mindIntegration}/bin/mind-agent-integration install-if-changed ${templatesJson} "$MIND_DIR/.obsidian/templates.json"
      ${mindIntegration}/bin/mind-agent-integration install-if-changed ${communityPluginsJson} "$MIND_DIR/.obsidian/community-plugins.json"
      ${mindIntegration}/bin/mind-agent-integration install-if-changed ${hotkeysJson} "$MIND_DIR/.obsidian/hotkeys.json"
      ${mindIntegration}/bin/mind-agent-integration sync-tree-if-changed \
        ${obsidianSource}/themes/soft-paper "$MIND_DIR/.obsidian/themes/Soft Paper"
      ${lib.concatMapStringsSep "\n" (plugin: ''
        ${mindIntegration}/bin/mind-agent-integration sync-tree-if-changed \
          ${plugin} "$MIND_DIR/.obsidian/plugins/${plugin.manifestId}"
      '') communityPluginList}
      ${mindIntegration}/bin/mind-agent-integration install-if-changed ${templaterJson} \
        "$MIND_DIR/.obsidian/plugins/templater-obsidian/data.json"

      {
        printf '%s\n' \
          '.obsidian/app.json' \
          '.obsidian/appearance.json' \
          '.obsidian/core-plugins.json' \
          '.obsidian/daily-notes.json' \
          '.obsidian/templates.json' \
          '.obsidian/community-plugins.json' \
          '.obsidian/hotkeys.json' \
          '.obsidian/themes/Soft Paper'
        ${lib.concatMapStringsSep "\n" (plugin: ''printf '%s\n' '.obsidian/plugins/${plugin.manifestId}' '') communityPluginList}
      } > "$NEXT_OBSIDIAN_MANIFEST"
      if [ -f "$OBSIDIAN_MANIFEST" ]; then
        while IFS= read -r rel; do
          [ -n "$rel" ] || continue
          grep -Fqx "$rel" "$NEXT_OBSIDIAN_MANIFEST" && continue
          ${mindIntegration}/bin/mind-agent-integration validate-managed-path \
            "$MIND_DIR" "$rel"
          case "$rel" in
            .obsidian/app.json|.obsidian/appearance.json|.obsidian/core-plugins.json|\
            .obsidian/daily-notes.json|.obsidian/templates.json|\
            .obsidian/community-plugins.json|.obsidian/hotkeys.json|\
            .obsidian/plugins/*|.obsidian/themes/*)
              chmod -R u+w "$MIND_DIR/$rel" 2>/dev/null || true
              rm -rf "$MIND_DIR/$rel"
              ;;
            *)
              echo "Refusing unexpected stale Obsidian path: $rel" >&2
              exit 1
              ;;
          esac
        done < "$OBSIDIAN_MANIFEST"
      fi
      ${mindIntegration}/bin/mind-agent-integration install-if-changed \
        "$NEXT_OBSIDIAN_MANIFEST" "$OBSIDIAN_MANIFEST"
      cat "$NEXT_OBSIDIAN_MANIFEST" >> "$STAGE_MANIFEST"
      printf '%s\n' '.nix-managed-obsidian-files' >> "$STAGE_MANIFEST"
      rm -f "$NEXT_OBSIDIAN_MANIFEST"

      # ── Global reach: ~/.claude entries are symlinks into the vault ─────
      # A pre-existing real directory is rescued into the vault first;
      # ln -sfn does NOT replace a real directory (it would create a link
      # INSIDE it), so the rm is required. No-op once the link exists.
      # ~/.claude/skills is linked by skills.nix to the shared skills root.
      mkdir -p "$HOME/.claude"
      mkdir -p "$MIND_DIR/.claude/output-styles"
      for entry in commands agents output-styles; do
        if [ -d "$HOME/.claude/$entry" ] && [ ! -L "$HOME/.claude/$entry" ]; then
          cp -Rn "$HOME/.claude/$entry"/. "$MIND_DIR/.claude/$entry/" 2>/dev/null || true
          rm -rf "$HOME/.claude/$entry"
        fi
        ln -sfn "$MIND_DIR/.claude/$entry" "$HOME/.claude/$entry"
      done
      # Rescue a real (non-symlink) global CLAUDE.md before replacing it.
      if [ -f "$HOME/.claude/CLAUDE.md" ] && [ ! -L "$HOME/.claude/CLAUDE.md" ] \
         && [ ! -f "$MIND_DIR/brain/CLAUDE-global.md" ]; then
        install -m644 "$HOME/.claude/CLAUDE.md" "$MIND_DIR/brain/CLAUDE-global.md"
      fi
      ln -sf "$MIND_DIR/brain/CLAUDE-global.md" "$HOME/.claude/CLAUDE.md"

      # Codex CLI reads ~/.codex/AGENTS.md as global instructions in every
      # project, same role as ~/.claude/CLAUDE.md. Point it at the same file.
      mkdir -p "$HOME/.codex"
      if [ -f "$HOME/.codex/AGENTS.md" ] && [ ! -L "$HOME/.codex/AGENTS.md" ]; then
        rm -f "$HOME/.codex/AGENTS.md"
      fi
      ln -sf "$MIND_DIR/brain/CLAUDE-global.md" "$HOME/.codex/AGENTS.md"

      # ── Settings split ──────────────────────────────────────────────────
      # The global ~/.claude/settings.json becomes a real user-owned file:
      # everything except hooks, hand-editable without a rebuild. The om
      # hooks live in the agent vault's .claude/settings.json (upstream's
      # hooks plus vault write rules) and fire only in vault sessions.
      # Both are seed-once. The old install symlinked the global path into
      # the human vault; the symlink must go first, or the -f guard follows
      # it and the seed never lands.
      if [ -L "$HOME/.claude/settings.json" ]; then
        rm "$HOME/.claude/settings.json"
      fi
      [ -f "$HOME/.claude/settings.json" ] || \
        install -m644 ${./config/claude/global-settings-seed.json} "$HOME/.claude/settings.json"
      [ -f "$MIND_DIR/.claude/settings.json" ] || \
        install -m644 ${./config/claude/mind-vault-settings-seed.json} "$MIND_DIR/.claude/settings.json"

      migrate_claude_settings() {
        target="$1"
        tmp="$(mktemp "''${target}.tmp.XXXXXX")"
        ${pkgs.jq}/bin/jq '
          .permissions.allow = (
            (.permissions.allow // [])
            | map(select(
                (contains("Documents/Mind")
                 or contains("Main/Daily_Notes")
                 or contains("Main/Templates"))
                | not
              ))
            | . + [
                "Read(~/Documents/Notes/**)",
                "Read(**/Documents/Notes/**)",
                "Edit(~/Documents/Notes/**)",
                "Edit(**/Documents/Notes/**)"
              ]
            | unique
          )
          | if .autoMemoryDirectory == "~/Documents/Mind/memories"
            then .autoMemoryDirectory = "~/Documents/Notes/memories"
            else . end
        ' "$target" > "$tmp"
        chmod --reference="$target" "$tmp" 2>/dev/null || chmod 600 "$tmp"
        mv "$tmp" "$target"
      }
      migrate_claude_settings "$HOME/.claude/settings.json"
      migrate_claude_settings "$MIND_DIR/.claude/settings.json"

      ${mindIntegration}/bin/mind-agent-integration export-skills "$MIND_DIR"
      ${mindIntegration}/bin/mind-agent-integration configure-instructions \
        "$MIND_DIR" ${omGlobalInstructions} ${omHermesInstructions}
    '';

    mindAgentClients = lib.hm.dag.entryAfter [ "agentVault" "aiAgents" ] ''
      MIND_DIR="$HOME/Documents/Notes"
      export JQ_BIN=${pkgs.jq}/bin/jq
      export YQ_BIN=${pkgs.yq-go}/bin/yq
      ${mindIntegration}/bin/mind-agent-integration configure-clients \
        "$MIND_DIR" "${config.home.homeDirectory}/.local/bin/om-mcp"
    '';

    mindGit = lib.hm.dag.entryAfter [ "agentSkills" "mindAgentClients" ] ''
      MIND_DIR="$HOME/Documents/Notes"
      ${mindIntegration}/bin/mind-agent-integration git-sync "$MIND_DIR" "${mindRevision}"
    '';
  };
}
