# Amazon/work-specific configuration — home-manager module.
#
# This module is always imported but only activates when `profile == "work"`.
# It adds:
#   - Amazon zshrc (toolbox, brazil, isengard, mechanic, etc.)
#   - Neovim amazon.lua plugin loading
#
# To switch profiles, change `profile = "work"` to `profile = "personal"`
# in flake.nix and rebuild.

{ config, lib, pkgs, profile ? "personal", ... }:

let
  isWork = profile == "work";
in

{
  config = lib.mkIf isWork {

    # ── Amazon zshrc additions ──────────────────────────────────────────
    programs.zsh.initContent = lib.mkAfter ''

      # --- Amazon things -------
      export PATH=$PATH:$HOME/.toolbox/bin
      eval "$(mise activate zsh)"
      source $HOME/.brazil_completion/zsh_completion

      # Enable autocompletion for mechanic.
      [ -f "$HOME/.local/share/mechanic/complete.zsh" ] && source "$HOME/.local/share/mechanic/complete.zsh"

      # Function to refresh AWS credentials

      export ISENGARD_ACCT=230312711150

      refresh_aws_credentials() {
          echo "Refreshing AWS credentials..."

          # Check if ISENGARD_ACCT is set, if not, prompt the user
          if [[ -z "$ISENGARD_ACCT" ]]; then
              echo "ISENGARD_ACCT is not set."
              read "ISENGARD_ACCT?Please enter your Isengard account number: "
              export ISENGARD_ACCT
          fi

          # Populate Isengard Credentials
          if eval $(isengardcli creds $ISENGARD_ACCT); then
              echo "Credentials successfully obtained from Isengard."

              # Compose bedrock keys
              BEDROCK_KEYS="$AWS_ACCESS_KEY_ID,$AWS_SECRET_ACCESS_KEY,us-west-2"
              if [[ -n "$AWS_SESSION_TOKEN" ]]; then
                  BEDROCK_KEYS="$BEDROCK_KEYS,$AWS_SESSION_TOKEN"
              fi
              export BEDROCK_KEYS

              echo "AWS credentials refreshed and BEDROCK_KEYS updated."
          else
              echo "Failed to obtain credentials from Isengard. Please check your account number and try again."
          fi
      }

      # Alias to call the function
      alias refresh_aws='refresh_aws_credentials'

      # Matts Hacky Stuff

      # Add necessary paths to PATH if they're not already present
      if [[ ":$PATH:" != *":/apollo/env/GokuDevTools/bin:"* ]]; then
          export PATH=$PATH:/apollo/env/GokuDevTools/bin
      fi

      if [[ ":$PATH:" != *":/apollo/env/envImprovement/bin:"* ]]; then
          export PATH=$PATH:/apollo/env/envImprovement/bin
      fi

      if [[ ":$PATH:" != *":/apollo/env/AmazonAwsCli/bin:"* ]]; then
          export PATH=$PATH:/apollo/env/AmazonAwsCli/bin
      fi

      if [[ ":$PATH:" != *":$HOME/workplace/Ops/src/MattsHackyStuffDotCom/bin:"* ]]; then
          export PATH=$PATH:$HOME/workplace/Ops/src/MattsHackyStuffDotCom/bin
      fi

      if [[ ":$PATH:" != *":$HOME/workplace/Ops/src/MattsHackyStuffDotCom/goku-ops:"* ]]; then
          export PATH=$PATH:$HOME/workplace/Ops/src/MattsHackyStuffDotCom/goku-ops
      fi

      # ---- Amazon Aliases -------------------------
      alias auth='kinit && mwinit -f && refresh_aws_credentials'
      alias bb=brazil-build

      alias bba='brazil-build apollo-pkg'
      alias bre='brazil-runtime-exec'
      alias brc='brazil-recursive-cmd'
      alias bws='brazil ws'
      alias bwsuse='bws use -p'
      alias bwscreate='bws create -n'
      alias brc=brazil-recursive-cmd
      alias bbr='brc brazil-build'
      alias bball='brc --allPackages'
      alias bbb='brc --allPackages brazil-build'
      alias bbra='bbr apollo-pkg'
    '';

    # ── Amazon shell aliases ────────────────────────────────────────────
    programs.zsh.shellAliases = {
      daily-summary = "cd ~/Documents/Notes && ./scripts/slack_summary.sh && ./scripts/asana_daily_summary.sh";
    };

    # ── Neovim Amazon plugins ───────────────────────────────────────────
    # amazon.lua is loaded automatically by lazy.nvim since it's in the
    # plugins directory. To disable on personal, we'd need to remove the
    # file — but since it requires Amazon network access, it's harmless
    # on personal machines (plugins just won't load).
  };
}
