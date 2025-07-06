{ config, pkgs, lib, home-manager, ... }:

let
  user = "nick";
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
        backupFileExtension = "backup";
      };
      # programs = {} // import ../shared/home-manager.nix { inherit config pkgs lib; };
      # manual.manpages.enable = false;
      # backupFileExtension = "backup";
  };

  # Fully declarative dock using the latest from Nix Store
  local = {
    dock.enable = true;
    dock.entries = [
      # { path = "/System/Applications/Finder.app/"; }
      { path = "/System/Applications/Launchpad.app/"; }
      { path = "/System/Applications/Mail.app/"; }
      # { path = "/System/Applications/Safari.app/"; }
      { path = "/System/Volumes/Preboot/Cryptexes/App/System/Applications/Safari.app/"; }
      { path = "/System/Applications/Messages.app/"; }
      { path = "/System/Applications/Calendar.app/"; }
      { path = "/System/Applications/Reminders.app/"; }
      { path = "/System/Applications/Notes.app/"; }
      { path = "/System/Applications/Photos.app/"; }
      { path = "/System/Applications/Maps.app/"; }
      { path = "/System/Applications/FaceTime.app/"; }
      { path = "/System/Applications/Music.app/"; }
      { path = "/System/Applications/Books.app/"; }
      { path = "${pkgs.iterm2}/Applications/iTerm2.app/"; }
      { path = "${pkgs.alacritty}/Applications/Alacritty.app/"; }
      # { path = "/Applications/Slack.app/"; }
      # {
      #   path = toString myEmacsLauncher;
      #   section = "others";
      # }
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
