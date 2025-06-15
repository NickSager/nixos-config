{ pkgs, config, lib, ... }:

# TODO: Update keys
let
  # Can put github public keys here to be copied
  nvimSource = ./config/nvim;
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

    ".config/iterm2.itermexport".source = ./config/iTerm2.itermexport;

    # Can copy over public keys as text
    # ".ssh/id_github.pub" = {
    #   text = githubPublicKey;
    # };
    #
    # ".ssh/pgp_github.pub" = {
    #   text = githubPublicSigningKey;
    # };
}
