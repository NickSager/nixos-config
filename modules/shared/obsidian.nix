# Obsidian vault — home-manager module shared across all platforms.
#
# Manages:
#   - home.file entries for templates, prompts, README, .gitignore (read-only symlinks)
#   - home.activation for mutable directories and script copies
#
# Based on https://code.amazon.com/packages/Thsvaugh-ObsidianDailySetup/trees/mainline
# TODO: Periodically check for updates from Thsvaugh's repo and sync changes
#       to templates, scripts, and prompts under modules/shared/config/obsidian/
#       Alternatively, uncomment the obsidian-daily-setup flake input in flake.nix
#       to fetch updates automatically via `nix flake update obsidian-daily-setup`.

{ lib, ... }:

let
  obsidianSource = ./config/obsidian;
  obsidianScriptsSource = ./config/obsidian/scripts;
  notesDir = "Documents/Notes";
in

{
  # ── Declarative plugin management (not yet active) ────────────────────
  # To enable:
  #   1. Add flake input: obsidian-plugins.url = "github:cjavad/nixpille-obsidian-community-plugins";
  #   2. Add the overlay from that flake to get pkgs.obsidianPlugins
  #   3. Uncomment the block below
  #   4. Remove obsidian from modules/shared/packages.nix (the module handles it)
  #
  # WARNING: Once enabled, community-plugins.json becomes read-only.
  #          You can no longer install plugins from within Obsidian.
  #          All plugins must be declared here and applied via build-switch.
  #
  # programs.obsidian = {
  #   enable = true;
  #   vaults.${notesDir} = {
  #     settings = {
  #       corePlugins = [
  #         "daily-notes"
  #         "templates"
  #         "backlink"
  #         "global-search"
  #         "graph"
  #         "outline"
  #         "tag-pane"
  #         "file-explorer"
  #         "command-palette"
  #         "bookmarks"
  #         "editor-status"
  #         "word-count"
  #       ];
  #       # Essential
  #       communityPlugins = with pkgs.obsidianPlugins; [
  #         obsidian-tasks            # Advanced task management
  #         obsidian-day-planner      # Time-blocking and meeting tracking
  #         dataview                  # SQL-like queries for notes
  #         templater-obsidian        # Dynamic templates
  #         nldates-obsidian          # Natural Language Dates
  #         # Recommended
  #         table-editor-obsidian     # Advanced Tables
  #         obsidian-plantuml         # Technical diagrams
  #         obsidian-emoji-shortcodes # Quick emoji insertion
  #         # Optional
  #         # obsidian-style-settings # Custom CSS configuration
  #         # obsidian-mindmap-nextgen # Auto-generated mindmaps
  #         # marp-slides             # Presentations from markdown
  #         # obsidian-image-toolkit  # Enhanced image viewing
  #       ];
  #     };
  #   };
  # };
  home.file = {
    # Templates: read-only symlinks (Obsidian reads these, never writes)
    "${notesDir}/Main/Templates/Daily_Note.md".source =
      obsidianSource + "/templates/Daily_Note.md";
    "${notesDir}/Main/Templates/PhoneTool Template.md".source =
      obsidianSource + "/templates/PhoneTool Template.md";

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

    # Mutable vault directories (created once, never overwritten)
    mkdir -p "$NOTES_DIR/Main/Daily_Notes"
    mkdir -p "$NOTES_DIR/Main/Phonetool"
    mkdir -p "$NOTES_DIR/Main/Meeting_Notes"

    # Copy scripts (always overwrite to pick up nix config changes)
    mkdir -p "$NOTES_DIR/scripts"
    install -m755 ${obsidianScriptsSource}/common_summary_functions.sh "$NOTES_DIR/scripts/common_summary_functions.sh"
    install -m755 ${obsidianScriptsSource}/slack_summary.sh            "$NOTES_DIR/scripts/slack_summary.sh"
    install -m755 ${obsidianScriptsSource}/taskei_daily_summary.sh     "$NOTES_DIR/scripts/taskei_daily_summary.sh"
    install -m755 ${obsidianScriptsSource}/monthly_summary_generator.sh "$NOTES_DIR/scripts/monthly_summary_generator.sh"
  '';
}
