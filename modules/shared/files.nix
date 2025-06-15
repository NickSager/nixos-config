{ pkgs, config, ... }:

# TODO: Update keys
let
  # Can put github public keys here to be copied
  nvimSource = ./config/nvim;
in

{
  home.file = {
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

    ".config/iterm2.itermexport".source = ./config/iTerm2.itermexport;

    # Can copy over public keys as text
    # ".ssh/id_github.pub" = {
    #   text = githubPublicKey;
    # };
    #
    # ".ssh/pgp_github.pub" = {
    #   text = githubPublicSigningKey;
    # };
  };

  home.activation.makeLazyWritable = config.lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    echo "Replacing lazy-lock.json with writable file..."
    LOCK_FILE="$HOME/.config/nvim/lazy-lock.json"
    if [ -L "$LOCK_FILE" ] || [ -e "$LOCK_FILE" ]; then
      rm -f "$LOCK_FILE"
    fi
    touch "$LOCK_FILE"
  '';

  # Or, copy an entirely mutable config directory
  # home.activation.copyNvimConfig = config.lib.hm.dag.entryAfter [ "writeBoundary" ] ''
  #   echo "Copying Neovim config to mutable location..."
  #   rm -rf "$HOME/.config/nvim"
  #   cp -R --no-preserve=mode,ownership ${nvimSource} "$HOME/.config/nvim"
  # '';
}
