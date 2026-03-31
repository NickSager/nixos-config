{ pkgs, config, lib, ... }:

# TODO: Update keys
let
  # Can put github public keys here to be copied
  nvimSource = ./config/nvim;

  claudeSettings = builtins.toJSON {
    awsAuthRefresh = "ada credentials update --profile claude --account $ISENGARD_ACCT --provider isengard --role Admin --once";
    env = {
      AWS_PROFILE = "claude";
      AWS_REGION = "us-west-2";
      ANTHROPIC_SMALL_FAST_MODEL_AWS_REGION = "us-west-2";
      CLAUDE_CODE_USE_BEDROCK = "1";
      DISABLE_BUG_COMMAND = "1";
      DISABLE_ERROR_REPORTING = "1";
      DISABLE_TELEMETRY = "1";
    };
    model = "global.anthropic.claude-opus-4-6-v1";
    alwaysThinkingEnabled = true;
    includeCoAuthoredBy = true;
    autoMemoryDirectory = "~/Documents/Notes/AI/memory";
    statusLine = {
      type = "command";
      command = "~/.claude/statusline.sh";
    };
    hooks = {
      SessionStart = [{
        matcher = "startup|resume|clear|compact";
        hooks = [{
          type = "command";
          command = "bash ~/Documents/Notes/.claude/scripts/session-start.sh";
          timeout = 30;
        }];
      }];
      UserPromptSubmit = [{
        hooks = [{
          type = "command";
          command = "bash ~/Documents/Notes/.claude/scripts/find-python.sh ~/Documents/Notes/.claude/scripts/classify-message.py";
          timeout = 15;
        }];
      }];
      PostToolUse = [{
        matcher = "Write|Edit";
        hooks = [{
          type = "command";
          command = "bash ~/Documents/Notes/.claude/scripts/find-python.sh ~/Documents/Notes/.claude/scripts/validate-write.py";
          timeout = 15;
        }];
      }];
      PreCompact = [{
        hooks = [{
          type = "command";
          command = "bash ~/Documents/Notes/.claude/scripts/pre-compact.sh";
          timeout = 30;
        }];
      }];
      Stop = [{
        hooks = [{
          type = "command";
          command = "echo 'Session end checklist:\n- Archive completed projects? (AI/work/active/ -> AI/work/archive/YYYY/)\n- Update indexes? (AI/work/Index.md, AI/brain/Memories.md, AI/org/People & Context.md, AI/perf/Brag Doc.md)\n- New notes linked? (orphans are bugs)\n- Run /om-vault-audit if many notes were created/modified'";
          timeout = 5;
        }];
      }];
    };
  };

  claudeStatusline = ''
    #!/bin/bash
    input=$(cat)

    MODEL=$(echo "$input" | jq -r '.model.display_name' | tr '[:upper:]' '[:lower:]')
    CONTEXT_SIZE=$(echo "$input" | jq -r '.context_window.context_window_size')
    USAGE=$(echo "$input" | jq '.context_window.current_usage')
    ADDED=$(echo "$input" | jq -r '.cost.total_lines_added // 0')
    REMOVED=$(echo "$input" | jq -r '.cost.total_lines_removed // 0')

    if [ "$USAGE" != "null" ]; then
      CURRENT_TOKENS=$(echo "$USAGE" | jq '.input_tokens + .cache_creation_input_tokens + .cache_read_input_tokens')
      PERCENT=$((CURRENT_TOKENS * 100 / CONTEXT_SIZE))
      printf "\033[38;2;218;119;86m%s\033[0m | ctx: %s%% | \033[38;2;54;152;64m+%s\033[0m \033[38;2;180;50;72m-%s\033[0m\n" "$MODEL" "$PERCENT" "$ADDED" "$REMOVED"
    else
      printf "\033[38;2;218;119;86m%s\033[0m | ctx: 0%% | \033[38;2;54;152;64m+%s\033[0m \033[38;2;180;50;72m-%s\033[0m\n" "$MODEL" "$ADDED" "$REMOVED"
    fi
  '';
in

{
    # Initializes Emacs with org-mode so we can tangle the main config
    #
    # @todo: Get rid of this after we've upgraded to Emacs 29 on the Macbook
    # Emacs 29 includes org-mode now
    ".emacs.d/init.el".text = builtins.readFile ./config/emacs/init.el;

    # Copy all Neovim configuration files
    ".config/nvim" = {
      source = nvimSource;
      recursive = true;
    };

    ".config/starship.toml".source = ./config/starship.toml;

    # Can copy over public keys as text
    # ".ssh/id_github.pub" = {
    #   text = githubPublicKey;
    # };
    #
    # ".ssh/pgp_github.pub" = {
    #   text = githubPublicSigningKey;
    # };

    # Claude Code configuration
    ".claude/settings.json".text = claudeSettings;
    ".claude/statusline.sh" = {
      text = claudeStatusline;
      executable = true;
    };

}
