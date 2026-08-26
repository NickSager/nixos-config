# Obsidian vaults — home-manager module shared across all platforms.
#
# Two vaults with a hard boundary:
#   - ~/Documents/Notes (human): daily notes, templates, personal notes.
#   - ~/Documents/Mind (agent): upstream obsidian-mind, copied from the
#     pinned flake input. Custom toolkit files live in it as plain vault
#     files nix never touches.

{ lib, pkgs, profile ? "personal", obsidian-mind ? null, ... }:

let
  obsidianSource = ./config/obsidian;
  obsidianScriptsSource = ./config/obsidian/scripts;
  obsidianPlugins = import ./obsidian-plugins.nix { inherit pkgs; };
  notesDir = "Documents/Notes";
  isWork = profile == "work";

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
      done
      for f in .claude/memory-template.md .claude/update-skills.ts .mcp.json \
               .shardmindignore AGENTS.md CLAUDE.md GEMINI.md Home.md vault-manifest.json; do
        install -m644 ${obsidian-mind}/$f "$MIND_DIR/$f"
      done

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
    '';
  };
}
