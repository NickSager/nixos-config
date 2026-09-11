_:

# TODO: Update keys
let
  # Can put github public keys here to be copied
  nvimSource = ./config/nvim;
  herdrConfig = ./config/herdr/config.toml;

  # NOTE: Claude Code's ~/.claude/settings.json is a real user-owned file,
  # seeded once by modules/shared/obsidian.nix and hand-editable without a
  # rebuild. Hooks live in the agent vault's .claude/settings.json.

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

    ".config/herdr/config.toml".source = herdrConfig;

    # Can copy over public keys as text
    # ".ssh/id_github.pub" = {
    #   text = githubPublicKey;
    # };
    #
    # ".ssh/pgp_github.pub" = {
    #   text = githubPublicSigningKey;
    # };

    # Claude Code configuration.
    # NOTE: ~/.claude/settings.json is intentionally NOT managed here. It is
    # seeded once by modules/shared/obsidian.nix and stays hand-editable
    # mid-session without a nix rebuild. Only the statusline is Nix-generated.
    ".claude/statusline.sh" = {
      text = claudeStatusline;
      executable = true;
    };

}
