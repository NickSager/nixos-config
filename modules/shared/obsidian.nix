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
  obsidianMindSource = ./config/obsidian/obsidian-mind;
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
                # obsidian-mind per-task notes under artifacts/<project>/tasks/
                # Templater applies folder_templates recursively to child folders.
                { folder = "AI/work/artifacts"; template = "AI/templates/Task.md"; }
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
    # ── obsidian-mind vault structure ──────────────────────────────────────
    # User content directories (created once, never overwritten)
    mkdir -p "$NOTES_DIR/AI/brain"
    mkdir -p "$NOTES_DIR/AI/work/incidents"
    mkdir -p "$NOTES_DIR/AI/work/1-1"
    mkdir -p "$NOTES_DIR/AI/work/meetings"

    # Projects directories (real files live here, visible in Obsidian)
    mkdir -p "$NOTES_DIR/Projects/active"
    mkdir -p "$NOTES_DIR/Projects/plans"
    mkdir -p "$NOTES_DIR/Projects/archive"

    # Symlink AI/work/{active,plans,archive} -> Projects/ so both
    # Claude (AI/ convention) and the user (Projects/ in Obsidian) see the same files.
    # Obsidian doesn't follow symlinks, so real files must be in Projects/.
    # Migration: if a real directory exists, move its contents to Projects/ first.
    for subdir in active plans archive; do
      target="$NOTES_DIR/AI/work/$subdir"
      if [ -d "$target" ] && [ ! -L "$target" ]; then
        # Real directory exists — move contents to Projects/, then replace with symlink
        cp -rn "$target"/* "$NOTES_DIR/Projects/$subdir/" 2>/dev/null || true
        rm -rf "$target"
      fi
      if [ ! -L "$target" ]; then
        ln -sfn "../../Projects/$subdir" "$target"
      fi
    done
    mkdir -p "$NOTES_DIR/AI/perf/brag"
    mkdir -p "$NOTES_DIR/AI/perf/evidence"
    mkdir -p "$NOTES_DIR/AI/perf/competencies"
    mkdir -p "$NOTES_DIR/AI/org/people"
    mkdir -p "$NOTES_DIR/AI/org/teams"
    mkdir -p "$NOTES_DIR/AI/thinking/session-logs"
    mkdir -p "$NOTES_DIR/AI/reference"
    mkdir -p "$NOTES_DIR/AI/memory"

    # Claude Code directories in vault
    mkdir -p "$NOTES_DIR/.claude/commands"
    mkdir -p "$NOTES_DIR/.claude/agents"
    mkdir -p "$NOTES_DIR/.claude/scripts"
    mkdir -p "$NOTES_DIR/.claude/skills/defuddle"
    mkdir -p "$NOTES_DIR/.claude/skills/qmd"
    mkdir -p "$NOTES_DIR/.claude/skills/obsidian-markdown/references"
    mkdir -p "$NOTES_DIR/.claude/skills/obsidian-bases/references"
    mkdir -p "$NOTES_DIR/.claude/skills/obsidian-cli"
    mkdir -p "$NOTES_DIR/.claude/skills/json-canvas/references"
    mkdir -p "$NOTES_DIR/.claude/skills/om-triage"
    mkdir -p "$NOTES_DIR/.claude/skills/om-triage-learn"

    # ── Nix-managed files (always overwrite to pick up config changes) ────

    # Hook scripts
    install -m755 ${obsidianMindSource}/scripts/session-start.sh     "$NOTES_DIR/.claude/scripts/session-start.sh"
    install -m755 ${obsidianMindSource}/scripts/classify-message.py  "$NOTES_DIR/.claude/scripts/classify-message.py"
    install -m755 ${obsidianMindSource}/scripts/validate-write.py    "$NOTES_DIR/.claude/scripts/validate-write.py"
    install -m755 ${obsidianMindSource}/scripts/pre-compact.sh       "$NOTES_DIR/.claude/scripts/pre-compact.sh"
    install -m755 ${obsidianMindSource}/scripts/find-python.sh       "$NOTES_DIR/.claude/scripts/find-python.sh"
    install -m755 ${obsidianMindSource}/scripts/charcount.sh         "$NOTES_DIR/.claude/scripts/charcount.sh"
    install -m755 ${obsidianMindSource}/scripts/test_hooks.py        "$NOTES_DIR/.claude/scripts/test_hooks.py"
    install -m755 ${obsidianMindSource}/scripts/ws-git-log.sh        "$NOTES_DIR/.claude/scripts/ws-git-log.sh"

    # Slash commands
    install -m644 ${obsidianMindSource}/commands/om-standup.md           "$NOTES_DIR/.claude/commands/om-standup.md"
    install -m644 ${obsidianMindSource}/commands/om-dump.md              "$NOTES_DIR/.claude/commands/om-dump.md"
    install -m644 ${obsidianMindSource}/commands/om-wrap-up.md           "$NOTES_DIR/.claude/commands/om-wrap-up.md"
    install -m644 ${obsidianMindSource}/commands/om-meeting.md           "$NOTES_DIR/.claude/commands/om-meeting.md"
    install -m644 ${obsidianMindSource}/commands/om-intake.md            "$NOTES_DIR/.claude/commands/om-intake.md"
    install -m644 ${obsidianMindSource}/commands/om-weekly.md            "$NOTES_DIR/.claude/commands/om-weekly.md"
    install -m644 ${obsidianMindSource}/commands/om-prep-1on1.md         "$NOTES_DIR/.claude/commands/om-prep-1on1.md"
    install -m644 ${obsidianMindSource}/commands/om-capture-1on1.md      "$NOTES_DIR/.claude/commands/om-capture-1on1.md"
    install -m644 ${obsidianMindSource}/commands/om-incident-capture.md  "$NOTES_DIR/.claude/commands/om-incident-capture.md"
    install -m644 ${obsidianMindSource}/commands/om-project-archive.md   "$NOTES_DIR/.claude/commands/om-project-archive.md"
    install -m644 ${obsidianMindSource}/commands/om-self-review.md       "$NOTES_DIR/.claude/commands/om-self-review.md"
    install -m644 ${obsidianMindSource}/commands/om-review-brief.md      "$NOTES_DIR/.claude/commands/om-review-brief.md"
    install -m644 ${obsidianMindSource}/commands/om-review-peer.md       "$NOTES_DIR/.claude/commands/om-review-peer.md"
    install -m644 ${obsidianMindSource}/commands/om-peer-scan.md         "$NOTES_DIR/.claude/commands/om-peer-scan.md"
    install -m644 ${obsidianMindSource}/commands/om-slack-scan.md        "$NOTES_DIR/.claude/commands/om-slack-scan.md"
    install -m644 ${obsidianMindSource}/commands/om-humanize.md          "$NOTES_DIR/.claude/commands/om-humanize.md"
    install -m644 ${obsidianMindSource}/commands/om-vault-audit.md       "$NOTES_DIR/.claude/commands/om-vault-audit.md"
    install -m644 ${obsidianMindSource}/commands/om-vault-upgrade.md     "$NOTES_DIR/.claude/commands/om-vault-upgrade.md"
    install -m644 ${obsidianMindSource}/commands/om-cr.md                "$NOTES_DIR/.claude/commands/om-cr.md"
    install -m644 ${obsidianMindSource}/commands/om-investigate-ticket.md "$NOTES_DIR/.claude/commands/om-investigate-ticket.md"
    install -m644 ${obsidianMindSource}/commands/om-batch-prompts.md    "$NOTES_DIR/.claude/commands/om-batch-prompts.md"
    install -m644 ${obsidianMindSource}/commands/om-triage.md           "$NOTES_DIR/.claude/commands/om-triage.md"
    install -m644 ${obsidianMindSource}/commands/om-triage-learn.md      "$NOTES_DIR/.claude/commands/om-triage-learn.md"

    # Subagents
    install -m644 ${obsidianMindSource}/agents/vault-librarian.md      "$NOTES_DIR/.claude/agents/vault-librarian.md"
    install -m644 ${obsidianMindSource}/agents/context-loader.md       "$NOTES_DIR/.claude/agents/context-loader.md"
    install -m644 ${obsidianMindSource}/agents/cross-linker.md         "$NOTES_DIR/.claude/agents/cross-linker.md"
    install -m644 ${obsidianMindSource}/agents/brag-spotter.md         "$NOTES_DIR/.claude/agents/brag-spotter.md"
    install -m644 ${obsidianMindSource}/agents/people-profiler.md      "$NOTES_DIR/.claude/agents/people-profiler.md"
    install -m644 ${obsidianMindSource}/agents/review-prep.md          "$NOTES_DIR/.claude/agents/review-prep.md"
    install -m644 ${obsidianMindSource}/agents/slack-archaeologist.md  "$NOTES_DIR/.claude/agents/slack-archaeologist.md"
    install -m644 ${obsidianMindSource}/agents/review-fact-checker.md  "$NOTES_DIR/.claude/agents/review-fact-checker.md"
    install -m644 ${obsidianMindSource}/agents/vault-migrator.md       "$NOTES_DIR/.claude/agents/vault-migrator.md"

    # Triage specialist subagents (om-triage)
    install -m644 ${obsidianMindSource}/agents/triage-failopen.md      "$NOTES_DIR/.claude/agents/triage-failopen.md"
    install -m644 ${obsidianMindSource}/agents/triage-failclosed.md    "$NOTES_DIR/.claude/agents/triage-failclosed.md"
    install -m644 ${obsidianMindSource}/agents/triage-host.md          "$NOTES_DIR/.claude/agents/triage-host.md"
    install -m644 ${obsidianMindSource}/agents/triage-deploy.md        "$NOTES_DIR/.claude/agents/triage-deploy.md"
    install -m644 ${obsidianMindSource}/agents/triage-rbr.md           "$NOTES_DIR/.claude/agents/triage-rbr.md"
    install -m644 ${obsidianMindSource}/agents/triage-log-diver.md     "$NOTES_DIR/.claude/agents/triage-log-diver.md"
    install -m644 ${obsidianMindSource}/agents/triage-metric-diver.md  "$NOTES_DIR/.claude/agents/triage-metric-diver.md"

    # Skills
    install -m644 ${obsidianMindSource}/skills/defuddle/SKILL.md                                  "$NOTES_DIR/.claude/skills/defuddle/SKILL.md"
    install -m644 ${obsidianMindSource}/skills/qmd/SKILL.md                                       "$NOTES_DIR/.claude/skills/qmd/SKILL.md"
    install -m644 ${obsidianMindSource}/skills/obsidian-markdown/SKILL.md                          "$NOTES_DIR/.claude/skills/obsidian-markdown/SKILL.md"
    install -m644 ${obsidianMindSource}/skills/obsidian-markdown/references/CALLOUTS.md            "$NOTES_DIR/.claude/skills/obsidian-markdown/references/CALLOUTS.md"
    install -m644 ${obsidianMindSource}/skills/obsidian-markdown/references/EMBEDS.md              "$NOTES_DIR/.claude/skills/obsidian-markdown/references/EMBEDS.md"
    install -m644 ${obsidianMindSource}/skills/obsidian-markdown/references/PROPERTIES.md          "$NOTES_DIR/.claude/skills/obsidian-markdown/references/PROPERTIES.md"
    install -m644 ${obsidianMindSource}/skills/obsidian-bases/SKILL.md                             "$NOTES_DIR/.claude/skills/obsidian-bases/SKILL.md"
    install -m644 ${obsidianMindSource}/skills/obsidian-bases/references/FUNCTIONS_REFERENCE.md    "$NOTES_DIR/.claude/skills/obsidian-bases/references/FUNCTIONS_REFERENCE.md"
    install -m644 ${obsidianMindSource}/skills/obsidian-cli/SKILL.md                               "$NOTES_DIR/.claude/skills/obsidian-cli/SKILL.md"
    install -m644 ${obsidianMindSource}/skills/json-canvas/SKILL.md                                "$NOTES_DIR/.claude/skills/json-canvas/SKILL.md"
    install -m644 ${obsidianMindSource}/skills/json-canvas/references/EXAMPLES.md                  "$NOTES_DIR/.claude/skills/json-canvas/references/EXAMPLES.md"
    install -m644 ${obsidianMindSource}/skills/om-triage/SKILL.md                                  "$NOTES_DIR/.claude/skills/om-triage/SKILL.md"
    install -m644 ${obsidianMindSource}/skills/om-triage-learn/SKILL.md                            "$NOTES_DIR/.claude/skills/om-triage-learn/SKILL.md"

    # Bases (Obsidian Bases query views)
    mkdir -p "$NOTES_DIR/AI/bases"
    install -m644 "${obsidianMindSource}/bases/1-1 History.base"        "$NOTES_DIR/AI/bases/1-1 History.base"
    install -m644 "${obsidianMindSource}/bases/Competency Map.base"     "$NOTES_DIR/AI/bases/Competency Map.base"
    install -m644 "${obsidianMindSource}/bases/Incidents.base"          "$NOTES_DIR/AI/bases/Incidents.base"
    install -m644 "${obsidianMindSource}/bases/People Directory.base"   "$NOTES_DIR/AI/bases/People Directory.base"
    install -m644 "${obsidianMindSource}/bases/Review Evidence.base"    "$NOTES_DIR/AI/bases/Review Evidence.base"
    install -m644 "${obsidianMindSource}/bases/Templates.base"          "$NOTES_DIR/AI/bases/Templates.base"
    install -m644 "${obsidianMindSource}/bases/Work Dashboard.base"     "$NOTES_DIR/AI/bases/Work Dashboard.base"

    # Templates (obsidian-mind note templates)
    mkdir -p "$NOTES_DIR/AI/templates"
    install -m644 "${obsidianMindSource}/templates/Work Note.md"        "$NOTES_DIR/AI/templates/Work Note.md"
    install -m644 "${obsidianMindSource}/templates/Review Template.md"  "$NOTES_DIR/AI/templates/Review Template.md"
    install -m644 "${obsidianMindSource}/templates/Thinking Note.md"    "$NOTES_DIR/AI/templates/Thinking Note.md"
    install -m644 "${obsidianMindSource}/templates/Decision Record.md"  "$NOTES_DIR/AI/templates/Decision Record.md"
    install -m644 "${obsidianMindSource}/templates/Competency Note.md"  "$NOTES_DIR/AI/templates/Competency Note.md"
    install -m644 "${obsidianMindSource}/templates/Task.md"             "$NOTES_DIR/AI/templates/Task.md"

    # Root-level AI files
    install -m644 ${obsidianMindSource}/Home.md             "$NOTES_DIR/AI/Home.md"
    install -m644 ${obsidianMindSource}/AGENTS.md            "$NOTES_DIR/AI/AGENTS.md"
    install -m644 ${obsidianMindSource}/vault-manifest.json  "$NOTES_DIR/AI/vault-manifest.json"
    install -m644 ${obsidianMindSource}/memory-template.md   "$NOTES_DIR/AI/memory-template.md"

    # ── Seed files (create once, never overwrite user edits) ──────────────

    # Vault-root CLAUDE.md
    [ -f "$NOTES_DIR/CLAUDE.md" ] || install -m644 ${obsidianSource + "/CLAUDE.md"} "$NOTES_DIR/CLAUDE.md"

    # Global CLAUDE.md (symlinked to ~/.claude/CLAUDE.md)
    [ -f "$NOTES_DIR/AI/brain/CLAUDE-global.md" ] || \
      install -m644 ${obsidianMindSource}/CLAUDE-global.md "$NOTES_DIR/AI/brain/CLAUDE-global.md"

    # Brain seeds
    [ -f "$NOTES_DIR/AI/brain/North Star.md" ] || \
      install -m644 "${obsidianMindSource}/brain/North Star.md" "$NOTES_DIR/AI/brain/North Star.md"
    [ -f "$NOTES_DIR/AI/brain/Memories.md" ] || \
      install -m644 ${obsidianMindSource}/brain/Memories.md "$NOTES_DIR/AI/brain/Memories.md"
    [ -f "$NOTES_DIR/AI/brain/Key Decisions.md" ] || \
      install -m644 "${obsidianMindSource}/brain/Key Decisions.md" "$NOTES_DIR/AI/brain/Key Decisions.md"
    [ -f "$NOTES_DIR/AI/brain/Patterns.md" ] || \
      install -m644 ${obsidianMindSource}/brain/Patterns.md "$NOTES_DIR/AI/brain/Patterns.md"
    [ -f "$NOTES_DIR/AI/brain/Gotchas.md" ] || \
      install -m644 ${obsidianMindSource}/brain/Gotchas.md "$NOTES_DIR/AI/brain/Gotchas.md"
    [ -f "$NOTES_DIR/AI/brain/Skills.md" ] || \
      install -m644 ${obsidianMindSource}/brain/Skills.md "$NOTES_DIR/AI/brain/Skills.md"

    # Work seeds
    [ -f "$NOTES_DIR/AI/work/Index.md" ] || \
      install -m644 ${obsidianMindSource}/work/Index.md "$NOTES_DIR/AI/work/Index.md"
    [ -f "$NOTES_DIR/AI/work/meetings/README.md" ] || \
      install -m644 ${obsidianMindSource}/work/meetings/README.md "$NOTES_DIR/AI/work/meetings/README.md"

    # Org seeds
    [ -f "$NOTES_DIR/AI/org/People & Context.md" ] || \
      install -m644 "${obsidianMindSource}/org/People & Context.md" "$NOTES_DIR/AI/org/People & Context.md"

    # Perf seeds
    [ -f "$NOTES_DIR/AI/perf/Brag Doc.md" ] || \
      install -m644 "${obsidianMindSource}/perf/Brag Doc.md" "$NOTES_DIR/AI/perf/Brag Doc.md"
    [ -f "$NOTES_DIR/AI/perf/competencies/README.md" ] || \
      install -m644 ${obsidianMindSource}/perf/competencies/README.md "$NOTES_DIR/AI/perf/competencies/README.md"

    # Thinking seed
    [ -f "$NOTES_DIR/AI/thinking/README.md" ] || \
      install -m644 ${obsidianMindSource}/thinking/README.md "$NOTES_DIR/AI/thinking/README.md"

    # ── Vault-level Claude Code settings ──────────────────────────────────
    # Seed vault permissions file on first install; never overwrite user edits.
    # Permissions are hand-editable throughout a session so Claude can add new
    # allow-list entries without requiring a nix rebuild.
    [ -f "$NOTES_DIR/.claude/settings.json" ] || \
      install -m644 ${obsidianMindSource}/claude-settings-seed.json "$NOTES_DIR/.claude/settings.json"

    # ── Symlinks from ~/.claude/ to vault ─────────────────────────────────
    ln -sfn "$NOTES_DIR/.claude/commands" "$HOME/.claude/commands"
    ln -sfn "$NOTES_DIR/.claude/agents"   "$HOME/.claude/agents"
    ln -sfn "$NOTES_DIR/.claude/skills"   "$HOME/.claude/skills"
    ln -sf  "$NOTES_DIR/AI/brain/CLAUDE-global.md" "$HOME/.claude/CLAUDE.md"
    # Expose vault permissions as Claude's user-level settings.local.json so
    # they apply globally (not just when CWD is inside the vault).
    ln -sfn "$NOTES_DIR/.claude/settings.json" "$HOME/.claude/settings.local.json"

    # ── Cleanup ───────────────────────────────────────────────────────────
    # Remove cole's memory-compiler local config if present
    rm -f "$NOTES_DIR/AI/.claude/settings.json" 2>/dev/null || true
    rmdir "$NOTES_DIR/AI/.claude" 2>/dev/null || true

    # Copy Obsidian daily scripts (always overwrite to pick up nix config changes)
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
