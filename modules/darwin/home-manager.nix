{ config, pkgs, lib, home-manager, ... }:

let
  user = "nsager";
  # Define the content of your file as a derivation
  myEmacsLauncher = pkgs.writeScript "emacs-launcher.command" ''
    #!/bin/sh
    emacsclient -c -n &
  '';
  # sharedFiles = import ../shared/files.nix { inherit config pkgs; };
  sharedFiles = import ../shared/files.nix {
    inherit pkgs config;
    lib = home-manager.lib;          #  ← gives files.nix the hm library
  };
  additionalFiles = import ./files.nix { inherit user config pkgs; };
in
{
  imports = [
    ./dock
  ];

  # It me
  system.primaryUser = user;
  users.users.${user} = {
    name     = "${user}";
    home     = "/Users/${user}";
    isHidden = false;
    shell    = pkgs.zsh;
  };

  homebrew = {
    # This is a module from nix-darwin
    # Homebrew is *installed* via the flake input nix-homebrew

    # These app IDs are from using the mas CLI app
    # mas = mac app store
    # https://github.com/mas-cli/mas
    #
    # $ nix shell nixpkgs#mas
    # $ mas search <app name>
    #
    enable = true;
    casks  = pkgs.callPackage ./casks.nix {};
    masApps = {
      # "hidden-bar" = 1452453066;
      # "wireguard" = 1451685025;
    };
  };

  home-manager = {
    useGlobalPkgs = true;
    users.${user} = { pkgs, config, lib, ... }:
      {
        imports = [ ../shared/obsidian.nix ];
        home = {
          enableNixpkgsReleaseCheck = false;
          packages = pkgs.callPackage ./packages.nix {};
          file = lib.mkMerge [
            sharedFiles
            additionalFiles
            { "emacs-launcher.command".source = myEmacsLauncher; }
          ];
          stateVersion = "23.11";
        };
        programs = {} // import ../shared/home-manager.nix { inherit config pkgs lib; };
        manual.manpages.enable = false;
        # backupFileExtension = "backup";
      };
      # programs = {} // import ../shared/home-manager.nix { inherit config pkgs lib; };
      # manual.manpages.enable = false;
      backupFileExtension = "backup";
  };

  # Fully declarative dock using the latest from Nix Store
  local = {
    dock.enable = true;
    dock.entries = [
      # { path = "/System/Applications/Finder.app/"; }
      { path = "/System/Applications/Launchpad.app/"; }
      { path = "/Applications/Microsoft Outlook.app/"; }
      { path = "/System/Applications/Calendar.app/"; }
      { path = "/System/Applications/Reminders.app/"; }
      { path = "/System/Applications/Notes.app/"; }
      { path = "${pkgs.obsidian}/Applications/Obsidian.app/"; }
      { path = "/Applications/Firefox.app/"; }
      { path = "${pkgs.iterm2}/Applications/iTerm2.app/"; }
      { path = "${pkgs.alacritty}/Applications/Alacritty.app/"; }
      { path = "/Applications/Slack.app/"; }
      {
        path = toString myEmacsLauncher;
        section = "others";
      }
      {
        path = "${config.users.users.${user}.home}/Downloads";
        section = "others";
        options = "--sort name --view grid --display stack";
      }
      # {
      #   path = "${config.users.users.${user}.home}/Trash";
      #   section = "others";
      #   # options = "--sort name --view grid --display stack";
      # }
    ];
  };

  ids.gids.nixbld = 350;

}
