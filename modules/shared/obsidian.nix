# Obsidian vaults — home-manager module shared across all platforms.
#
# Two vaults with a hard boundary:
#   - ~/Documents/Notes (human): daily notes, templates, personal notes.
#   - ~/Documents/Mind (agent): upstream obsidian-mind, copied from the
#     pinned flake input. Custom toolkit files live in it as plain vault
#     files nix never touches.

{ config, lib, pkgs, profile ? "personal", obsidian-mind ? null, ... }:

let
  obsidianSource = ./config/obsidian;
  obsidianScriptsSource = ./config/obsidian/scripts;
  notesClaude = obsidianSource + "/CLAUDE.md";
  obsidianPlugins = import ./obsidian-plugins.nix { inherit pkgs; };
  notesDir = "Documents/Notes";
  isWork = profile == "work";
  mindRevision = if obsidian-mind == null then "unknown" else obsidian-mind.rev or "unknown";
  mindIntegration = ./scripts/mind-agent-integration.sh;
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
    exec ${pkgs.nodejs}/bin/node "$HOME/Documents/Mind/.claude/scripts/om-mcp.mjs"
  '';

  # Hotkeys must be a writable copy — Obsidian ignores read-only symlinks.
  hotkeysJson = (pkgs.formats.json { }).generate "hotkeys.json" {
    "file-explorer:new-file" = [];
    "daily-notes" = [{ modifiers = ["Mod"]; key = "D"; }];
    "templater-obsidian:create-new-note-from-template" = [{ modifiers = ["Mod"]; key = "N"; }];
  };
in

{
  # ── Declarative plugin management ──────────────────────────────────────
  # community-plugins.json is read-only once this is active.
  # To add/remove plugins, edit obsidian-plugins.nix and run build-switch.
  programs.obsidian = {
    enable = true;
    vaults.${notesDir} = {
      settings = {
        corePlugins = [
          {
            name = "daily-notes";
            settings = {
              folder = "Main/Daily_Notes";
              format = "YYYY/YYYY-MM/YYYY-MM-DD";
              template = "Main/Templates/Daily_Note";
            };
          }
          "templates"
          "backlink"
          "global-search"
          "graph"
          "outline"
          "tag-pane"
          "file-explorer"
          "command-palette"
          "bookmarks"
          "editor-status"
          "word-count"
          "bases"
        ];
        appearance = { cssTheme = "Soft Paper"; };
        extraFiles."themes/Soft Paper".source = obsidianSource + "/themes/soft-paper";
        communityPlugins = with obsidianPlugins; [
          obsidian-tasks-plugin       # Advanced task management
          dataview                    # SQL-like queries for notes
          {
            pkg = templater-obsidian;
            settings = {
              command_timeout = 5;
              templates_folder = "Main/Templates";
              templates_pairs = [["" ""]];
              trigger_on_file_creation = true;
              auto_jump_to_cursor = true;
              enable_system_commands = false;
              shell_path = "";
              user_scripts_folder = "";
              enable_folder_templates = true;
              folder_templates = [
                { folder = "Main/Daily_Notes"; template = "Main/Templates/Daily_Note.md"; }
                { folder = "Main/Meeting_Notes"; template = "Main/Templates/Meeting_Note.md"; }
                { folder = "Projects"; template = "Main/Templates/Project.md"; }
                { folder = "Tasks"; template = "Main/Templates/Task.md"; }
              ];
              enable_file_templates = false;
              file_templates = [{ regex = ".*"; template = ""; }];
              syntax_highlighting = true;
              syntax_highlighting_mobile = false;
              enabled_templates_hotkeys = [""];
              startup_templates = [""];
              intellisense_render = 1;
            };
          }
          nldates-obsidian            # Natural Language Dates
          vim-yank-highlight          # Visual feedback for vim users
        ];
      };
    };
  };

  home.file = {
    ".local/bin/om-mcp" = {
      source = omMcpWrapper;
      executable = true;
    };

    # Templates: read-only symlinks (Obsidian reads these, never writes)
    "${notesDir}/Main/Templates/Daily_Note.md".source =
      obsidianSource + "/templates/Daily_Note.md";
    "${notesDir}/Main/Templates/Meeting_Note.md".source =
      obsidianSource + "/templates/Meeting_Note.md";
    "${notesDir}/Main/Templates/Project.md".source =
      obsidianSource + "/templates/Project.md";
    "${notesDir}/Main/Templates/Task.md".source =
      obsidianSource + "/templates/Task.md";

    # Prompts: read-only symlinks (scripts read these, never write)
    "${notesDir}/prompts" = {
      source = obsidianSource + "/prompts";
      recursive = true;
    };

    # README and .gitignore for the vault
    "${notesDir}/README.md".source = obsidianSource + "/README.md";
    "${notesDir}/.gitignore".source = obsidianSource + "/vault-gitignore";
  };

  home.activation = {
    # ── Human vault (~/Documents/Notes) ────────────────────────────────────
    # Mutable directories and script copies. Scripts are copied (not
    # symlinked) so their relative paths (e.g. ../prompts/) resolve inside
    # the vault rather than into the Nix store.
    obsidianVault = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      NOTES_DIR="$HOME/Documents/Notes"

      # The human vault's instructions are seeded once so later local edits
      # remain user-owned while new vaults never receive the retired Notes/AI
      # architecture.
      [ -e "$NOTES_DIR/CLAUDE.md" ] || \
        install -m644 ${notesClaude} "$NOTES_DIR/CLAUDE.md"

      # Hotkeys: copy as writable file (Obsidian ignores read-only symlinks)
      install -m644 ${hotkeysJson} "$NOTES_DIR/.obsidian/hotkeys.json"

      # Mutable vault directories (created once, never overwritten)
      mkdir -p "$NOTES_DIR/Main/Daily_Notes"
      mkdir -p "$NOTES_DIR/Main/Meeting_Notes"
      mkdir -p "$NOTES_DIR/Inbox"
      mkdir -p "$NOTES_DIR/Projects/active"
      mkdir -p "$NOTES_DIR/Projects/plans"
      mkdir -p "$NOTES_DIR/Projects/archive"
      mkdir -p "$NOTES_DIR/Tasks"

      # Copy Obsidian daily scripts (always overwrite to pick up nix config changes)
      mkdir -p "$NOTES_DIR/scripts"
      install -m755 ${obsidianScriptsSource}/common_summary_functions.sh "$NOTES_DIR/scripts/common_summary_functions.sh"
      install -m755 ${obsidianScriptsSource}/slack_summary.sh            "$NOTES_DIR/scripts/slack_summary.sh"
      install -m755 ${obsidianScriptsSource}/monthly_summary_generator.sh "$NOTES_DIR/scripts/monthly_summary_generator.sh"
    '';
  } // lib.optionalAttrs (obsidian-mind != null) {
    # ── Agent vault (~/Documents/Mind) ─────────────────────────────────────
    # Upstream obsidian-mind lands here from the pinned flake input.
    # An upgrade is: bump the tag in flake.nix, `nix flake update
    # obsidian-mind`, read the upstream CHANGELOG, rebuild.
    agentVault = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      MIND_DIR="$HOME/Documents/Mind"
      mkdir -p "$MIND_DIR/memories"

      MANAGED_MANIFEST="$MIND_DIR/.obsidian-mind-managed-files"
      STAGE_MANIFEST="$MIND_DIR/.obsidian-mind-stage-paths"
      NEXT_MANIFEST="$(mktemp "$MIND_DIR/.obsidian-mind-managed-files.tmp.XXXXXX")"
      if [ -f "$MANAGED_MANIFEST" ]; then
        cat "$MANAGED_MANIFEST" >> "$STAGE_MANIFEST"
        while IFS= read -r rel; do
          [ -n "$rel" ] || continue
          case "$rel" in
            /*|..|../*|*/..|*/../*)
              echo "Refusing unsafe managed Mind path: $rel" >&2
              exit 1
              ;;
          esac
          case "$rel" in
            .claude/agents/*|.claude/commands/*|.claude/scripts/*|.claude/skills/*|\
            .claude-plugin/*|.codex/*|.gemini/*|.scripts/*|.shardmind/*|bases/*|templates/*|\
            .claude/memory-template.md|.claude/update-skills.ts|.mcp.json|.shardmindignore|\
            AGENTS.md|CLAUDE.md|GEMINI.md|Home.md|vault-manifest.json)
              rm -f "$MIND_DIR/$rel"
              ;;
            *)
              echo "Refusing unexpected managed Mind path: $rel" >&2
              exit 1
              ;;
          esac
        done < "$MANAGED_MANIFEST"
      fi

      # Machinery: always overwritten so a release-tag bump lands on the
      # next rebuild. cp -Rf replaces same-named files but leaves the
      # custom toolkit (plain sibling files in the same directories) alone.
      # A new upstream top-level directory needs one entry here.
      for dir in .claude/agents .claude/commands .claude/scripts .claude/skills \
                 .claude-plugin .codex .gemini .scripts .shardmind bases templates; do
        mkdir -p "$MIND_DIR/$dir"
        # An interrupted prior run can leave read-only store-mode copies;
        # cp -Rf cannot replace files inside a read-only directory.
        chmod -R u+w "$MIND_DIR/$dir" 2>/dev/null || true
        cp -Rf ${obsidian-mind}/$dir/. "$MIND_DIR/$dir/"
        find ${obsidian-mind}/$dir \( -type f -o -type l \) -print | \
          sed "s#^${obsidian-mind}/##" >> "$NEXT_MANIFEST"
      done
      for f in .claude/memory-template.md .claude/update-skills.ts .mcp.json \
               .shardmindignore AGENTS.md CLAUDE.md GEMINI.md Home.md vault-manifest.json; do
        install -m644 ${obsidian-mind}/$f "$MIND_DIR/$f"
        printf '%s\n' "$f" >> "$NEXT_MANIFEST"
      done

      cat ${omWrapUpAddon} >> "$MIND_DIR/.claude/commands/om-wrap-up.md"
      sort -u "$NEXT_MANIFEST" -o "$NEXT_MANIFEST"
      install -m644 "$NEXT_MANIFEST" "$MANAGED_MANIFEST"
      cat "$NEXT_MANIFEST" >> "$STAGE_MANIFEST"
      printf '%s\n' '.obsidian-mind-managed-files' >> "$STAGE_MANIFEST"
      rm -f "$NEXT_MANIFEST"

      # Content: seeded once, never overwritten (user-owned notes and
      # Obsidian state). cp -Rn adds files a new release ships without
      # touching existing ones. .claude/settings.json is deliberately not
      # copied here; the settings split owns it.
      for dir in .obsidian brain org perf reference thinking work; do
        mkdir -p "$MIND_DIR/$dir"
        cp -Rn ${obsidian-mind}/$dir/. "$MIND_DIR/$dir/" 2>/dev/null || true
      done

      # Store copies arrive read-only; the vault must stay editable.
      chmod -R u+w "$MIND_DIR"

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

      ${pkgs.bash}/bin/bash ${mindIntegration} export-skills "$MIND_DIR"
      ${pkgs.bash}/bin/bash ${mindIntegration} configure-instructions \
        "$MIND_DIR" ${omGlobalInstructions} ${omHermesInstructions}
    '';

    mindAgentClients = lib.hm.dag.entryAfter [ "agentVault" "aiAgents" ] ''
      MIND_DIR="$HOME/Documents/Mind"
      export JQ_BIN=${pkgs.jq}/bin/jq
      export YQ_BIN=${pkgs.yq-go}/bin/yq
      ${pkgs.bash}/bin/bash ${mindIntegration} configure-clients \
        "$MIND_DIR" "${config.home.homeDirectory}/.local/bin/om-mcp"
    '';

    mindGit = lib.hm.dag.entryAfter [ "agentSkills" "mindAgentClients" ] ''
      MIND_DIR="$HOME/Documents/Mind"
      export PATH="${pkgs.git}/bin:$PATH"
      ${pkgs.bash}/bin/bash ${mindIntegration} git-sync "$MIND_DIR" "${mindRevision}"
    '';
  };
}
