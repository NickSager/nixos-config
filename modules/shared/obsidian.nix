# Obsidian vault — home-manager module shared across all platforms.
#
# Manages:
#   - programs.obsidian with declarative community plugins
#   - home.file entries for templates, prompts, README, .gitignore (read-only symlinks)
#   - home.activation for mutable directories and script copies
#
# Based on https://code.amazon.com/packages/Thsvaugh-ObsidianDailySetup/trees/mainline
# TODO: Periodically check for updates from Thsvaugh's repo and sync changes
#       to templates, scripts, and prompts under modules/shared/config/obsidian/
#       Alternatively, uncomment the obsidian-daily-setup flake input in flake.nix
#       to fetch updates automatically via `nix flake update obsidian-daily-setup`.

{ lib, pkgs, profile ? "personal", ... }:

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
        ];
        appearance = { cssTheme = "Soft Paper"; };
        extraFiles."themes/Soft Paper".source = obsidianSource + "/themes/soft-paper";
        communityPlugins = with obsidianPlugins; [
          # Essential
          obsidian-tasks-plugin       # Advanced task management
          obsidian-day-planner        # Time-blocking and meeting tracking
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
          # Recommended
          markdown-table-editor       # Advanced Tables
          obsidian-plantuml           # Technical diagrams
          emoji-shortcodes            # Quick emoji insertion
          obsidian-emoji-toolbar      # Emoji picker
          # Optional
          {
            pkg = obsidian-style-settings;
            settings = {
              "soft-paper-settings@@sp-hide-scrollbars" = true;
              "soft-paper-settings@@sp-compact-bases" = false;
              "soft-paper-settings@@sp-compact-explorer" = false;
              "soft-paper-settings@@sp-hide-add-property" = false;
              "soft-paper-settings@@sp-status-bar-blue" = false;
              "soft-paper-settings@@sp-settings-transparent" = false;
            };
          }
          obsidian-mindmap-nextgen    # Auto-generated mindmaps
          marp-slides                 # Presentations from markdown
          obsidian-image-toolkit      # Enhanced image viewing
          simple-time-tracker         # Detailed time tracking
          vim-yank-highlight          # Visual feedback for vim users
        ];
      };
    };
  };

  home.file = {
    # Templates: read-only symlinks (Obsidian reads these, never writes)
    "${notesDir}/Main/Templates/Daily_Note.md".source =
      obsidianSource + "/templates/Daily_Note.md";
    "${notesDir}/Main/Templates/PhoneTool Template.md".source =
      obsidianSource + "/templates/PhoneTool Template.md";
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

  # Create mutable vault directories and copy scripts.
  # Scripts are copied (not symlinked) so their relative paths
  # (e.g. ../prompts/, ../Main/Daily_Notes/) resolve inside the vault
  # rather than into the Nix store.
  home.activation.obsidianVault = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    NOTES_DIR="$HOME/Documents/Notes"

    # Hotkeys: copy as writable file (Obsidian ignores read-only symlinks)
    install -m644 ${hotkeysJson} "$NOTES_DIR/.obsidian/hotkeys.json"

    # Mutable vault directories (created once, never overwritten)
    mkdir -p "$NOTES_DIR/Main/Daily_Notes"
    mkdir -p "$NOTES_DIR/Main/Phonetool"
    mkdir -p "$NOTES_DIR/Main/Meeting_Notes"
    mkdir -p "$NOTES_DIR/Inbox"
    mkdir -p "$NOTES_DIR/Projects"
    mkdir -p "$NOTES_DIR/Tasks"
    mkdir -p "$NOTES_DIR/AI/Context"
    mkdir -p "$NOTES_DIR/AI/Agents"
    mkdir -p "$NOTES_DIR/AI/Skills"

    # AI context: seed files (copy only if absent, never overwrite user edits)
    [ -f "$NOTES_DIR/CLAUDE.md" ] || install -m644 ${obsidianSource + "/CLAUDE.md"} "$NOTES_DIR/CLAUDE.md"
    [ -f "$NOTES_DIR/AI/Context/README.md" ] || install -m644 ${obsidianSource + "/ai-context/README.md"} "$NOTES_DIR/AI/Context/README.md"

    # Copy scripts (always overwrite to pick up nix config changes)
    mkdir -p "$NOTES_DIR/scripts"
    install -m755 ${obsidianScriptsSource}/common_summary_functions.sh "$NOTES_DIR/scripts/common_summary_functions.sh"
    install -m755 ${obsidianScriptsSource}/slack_summary.sh            "$NOTES_DIR/scripts/slack_summary.sh"
    install -m755 ${obsidianScriptsSource}/asana_daily_summary.sh      "$NOTES_DIR/scripts/asana_daily_summary.sh"
    install -m755 ${obsidianScriptsSource}/monthly_summary_generator.sh "$NOTES_DIR/scripts/monthly_summary_generator.sh"
    ${lib.optionalString isWork ''
    # Work-only: code_summary.sh requires code.amazon.com API + builder-mcp
    install -m755 ${obsidianScriptsSource}/code_summary.sh             "$NOTES_DIR/scripts/code_summary.sh"
    ''}
  '';
}
