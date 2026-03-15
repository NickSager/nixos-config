{ config, osConfig, pkgs, lib, home-manager, ... }:

let
  user = "nick";
  # sharedFiles = import ../shared/files.nix { inherit config pkgs; };
  sharedFiles = import ../shared/files.nix {
    inherit pkgs config;
    lib = home-manager.lib;          #  ← gives files.nix the hm library
  };
  additionalFiles = import ./files.nix { inherit user config pkgs; };
in {
  imports = [
    ../shared/obsidian.nix
    ../shared/work.nix
  ];

  home = {
    username = user;
    homeDirectory = "/home/${user}";
    enableNixpkgsReleaseCheck = false;
    packages = pkgs.callPackage ./packages.nix { };
    sessionPath = [ "$HOME/.local/bin" ];
    sessionVariables = {
      # EDITOR = "${pkgs.my-emacs-with-packages}/bin/emacsclient";
    };
    file = lib.mkMerge [ sharedFiles additionalFiles ];
    stateVersion = "23.11";
  };

  news.display = "silent";

  fonts.fontconfig.enable = true;

  programs = { } // import ../shared/home-manager.nix {
    inherit config osConfig pkgs lib;
  };
}
