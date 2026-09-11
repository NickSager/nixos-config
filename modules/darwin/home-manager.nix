{ config, pkgs, lib, home-manager, user, profile, obsidian-mind, pstack, pocock, ... }:

let
  defaultNodeVersion = "24.19.0";
  nvmScript = "${config.homebrew.prefix}/opt/nvm/nvm.sh";
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
    onActivation = {
      upgrade = true;     # `brew upgrade` installed casks on every build-switch
      autoUpdate = false; # `brew update` fails under mutableTaps = false
      cleanup = "none";   # don't uninstall undeclared casks
    };
    brews = [ "nvm" ];
    casks = pkgs.callPackage ./casks.nix { inherit profile; };
    masApps = {
      # "Amphetamine" = 937984704; # Keep-awake w/ triggers + closed-display mode (App Store only)
      # "hidden-bar" = 1452453066;
      # "wireguard" = 1451685025;
    };
  };

  home-manager = {
    useGlobalPkgs = true;
    extraSpecialArgs = { inherit profile obsidian-mind pstack pocock; };
    users.${user} = { pkgs, config, lib, ... }:
      {
        imports = [
          ../shared/obsidian.nix
          ../shared/skills.nix
          ../shared/ai-agents.nix
          ../shared/hermes-config.nix
        ];
        home = {
          enableNixpkgsReleaseCheck = false;
          packages = pkgs.callPackage ./packages.nix {};
          sessionPath = [ "$HOME/.local/bin" ];
          file = lib.mkMerge [
            sharedFiles
            additionalFiles
            { "emacs-launcher.command".source = myEmacsLauncher; }
          ];
          activation.nvmDefaultNode = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
            export NVM_DIR="$HOME/.nvm"
            $DRY_RUN_CMD mkdir -p "$NVM_DIR"

            if [ ! -s "${nvmScript}" ]; then
              echo "nvm initialization script not found: ${nvmScript}" >&2
              exit 1
            fi

            . "${nvmScript}"
            if [ "$(nvm version "${defaultNodeVersion}")" = "N/A" ]; then
              $DRY_RUN_CMD nvm install "${defaultNodeVersion}"
            fi
            $DRY_RUN_CMD nvm alias default "${defaultNodeVersion}"
          '';
          stateVersion = "23.11";
        };
        programs = lib.mkMerge [
          (import ../shared/home-manager.nix { inherit config pkgs lib user; })
          {
            zsh.initContent = lib.mkAfter ''
              export NVM_DIR="$HOME/.nvm"
              if [ -s "${nvmScript}" ]; then
                . "${nvmScript}"
                nvm use --silent default >/dev/null 2>&1
              fi
              export PATH="${pkgs.pnpm_11}/bin:${pkgs.nest-cli}/bin:$PATH"
            '';
          }
        ];
        manual.manpages.enable = false;
        # backupFileExtension = "backup";
      };
      # programs = {} // import ../shared/home-manager.nix { inherit config pkgs lib; };
      # manual.manpages.enable = false;
      backupFileExtension = "backup";
  };

  system.defaults.dock = {
    persistent-apps =
      if profile == "work" then [
        { app = "/System/Applications/Apps.app"; }
        { app = "/Applications/Microsoft Outlook.app"; }
        { app = "/Applications/Microsoft Teams.app"; }
        { app = "/System/Volumes/Preboot/Cryptexes/App/System/Applications/Safari.app"; }
        { app = "/System/Applications/Calendar.app"; }
        { app = "/System/Applications/Reminders.app"; }
        { app = "/System/Applications/Notes.app"; }
        { app = "${pkgs.obsidian}/Applications/Obsidian.app"; }
        { app = "${pkgs.alacritty}/Applications/Alacritty.app"; }
      ] else [
        { app = "/System/Applications/Apps.app"; }
        { app = "/System/Applications/Mail.app"; }
        { app = "/System/Volumes/Preboot/Cryptexes/App/System/Applications/Safari.app"; }
        { app = "/System/Applications/Messages.app"; }
        { app = "/System/Applications/Calendar.app"; }
        { app = "/System/Applications/Reminders.app"; }
        { app = "/System/Applications/Notes.app"; }
        { app = "/System/Applications/Photos.app"; }
        { app = "/System/Applications/Maps.app"; }
        { app = "/System/Applications/FaceTime.app"; }
        { app = "/System/Applications/Music.app"; }
        { app = "/System/Applications/Books.app"; }
        { app = "${pkgs.obsidian}/Applications/Obsidian.app"; }
        { app = "${pkgs.alacritty}/Applications/Alacritty.app"; }
      ];

    persistent-others = [
      {
        folder = {
          path = "${config.users.users.${user}.home}/Downloads";
          arrangement = "name";
          displayas = "stack";
          showas = "grid";
        };
      }
    ];
  };

  ids.gids.nixbld = 350;

}
