{ agenix, config, pkgs, user, ... }:
{
  imports = [
    # ../../modules/darwin/secrets.nix
    ../../modules/darwin/home-manager.nix
    ../../modules/shared
    agenix.darwinModules.default
  ];
  # Setup user, packages, programs
  nix = {
    package = pkgs.nix;
    settings = {
      trusted-users = [ "@admin" "${user}" ];
      substituters = [ "https://nix-community.cachix.org" "https://cache.nixos.org" ];
      trusted-public-keys = [ "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY=" ];
    };
    gc = {
      automatic = true;
      interval = { Weekday = 0; Hour = 2; Minute = 0; };
      options = "--delete-older-than 30d";
    };
    # Turn this on to make command line easier
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
  };
  # Load configuration that is shared across systems
  environment.systemPackages = with pkgs; [
    emacs
    agenix.packages."${pkgs.stdenv.hostPlatform.system}".default
  ] ++ (import ../../modules/shared/packages.nix { inherit pkgs; });

  #launchd.user.agents = {
  #  emacs = {
  #    path = [ config.environment.systemPath ];
  #    serviceConfig = {
  #      KeepAlive = true;
  #      ProgramArguments = [
  #        "/bin/sh"
  #        "-c"
  #        "{ osascript -e 'display notification \"Attempting to start Emacs...\" with title \"Emacs Launch\"'; /bin/wait4path ${pkgs.emacs}/bin/emacs && { ${pkgs.emacs}/bin/emacs --fg-daemon; if [ $? -eq 0 ]; then osascript -e 'display notification \"Emacs has started.\" with title \"Emacs Launch\"'; else osascript -e 'display notification \"Failed to start Emacs.\" with title \"Emacs Launch\"' >&2; fi; } } &> /tmp/emacs_launch.log"
  #      ];
  #      StandardErrorPath = "/tmp/emacs.err.log";
  #      StandardOutPath = "/tmp/emacs.out.log";
  #    };
  #  };
  #};

  # Clean up broken symlinks in Homebrew's zsh site-functions (nix-homebrew#77)
  system.activationScripts.postActivation.text = ''
    if [ -d /opt/homebrew/share/zsh/site-functions ]; then
      find /opt/homebrew/share/zsh/site-functions -maxdepth 1 -type l ! -exec test -e {} \; -delete
    fi
  '';

  system = {
    # Turn off NIX_PATH warnings now that we're using flakes
    checks.verifyNixPath = false;
    primaryUser = user;
    stateVersion = 4;
    defaults = {
      LaunchServices = {
        LSQuarantine = false;
      };
      NSGlobalDomain = {
        AppleShowAllExtensions = true;
        ApplePressAndHoldEnabled = false;

        # 120, 90, 60, 30, 12, 6, 2
        KeyRepeat = 2;

        # 120, 94, 68, 35, 25, 15
        InitialKeyRepeat = 15;
        "com.apple.mouse.tapBehavior" = 1;
        "com.apple.sound.beep.volume" = 0.0;
        "com.apple.sound.beep.feedback" = 0;
      };
      dock = {
        autohide = true;
        show-recents = false;
        launchanim = true;
        mouse-over-hilite-stack = true;
        orientation = "left";
        tilesize = 36;
      };
      finder = {
        _FXShowPosixPathInTitle = false;
        FXPreferredViewStyle = "clmv"; # Column view
      };
      trackpad = {
        Clicking = true;
        TrackpadThreeFingerDrag = false;
        Dragging = true;              # Enable tap-to-drag
        # DragLock = true;              # Enable drag lock
      };

      screensaver = {
        askForPassword = true;
        askForPasswordDelay = 5; # Seconds
      };

      # Hot corners
      # Possible values:
      #  0: no-op
      #  2: Mission Control
      #  3: Show application windows
      #  4: Desktop
      #  5: Start screen saver
      #  6: Disable screen saver
      #  7: Dashboard
      # 10: Put display to sleep
      # 11: Launchpad
      # 12: Notification Center
      # 13: Lock Screen
      # 14: Quick Note
      loginwindow = {
        GuestEnabled = false;
        SHOWFULLNAME = false;
      };

      CustomUserPreferences = {
        "com.apple.screensaver" = {
          idleTime = 300; # 5 minutes
        };
        # Hot corners
        "com.apple.dock" = {
          wvous-tr-corner = 5; # Top right corner starts screensaver
          wvous-tr-modifier = 0;
        };
        system.defaults."com.apple.AppleMultitouchTrackpad" = {
          Clicking = true;              # Enable tap-to-click
          Dragging = 1;                 # Enable drag with Drag Lock
          TrackpadThreeFingerDrag = false; # Ensure Three-Finger Drag is disabled to avoid conflicts
        };
      };
    };
    keyboard = {
      enableKeyMapping = true;
      # remapCapsLockToControl = true;
      remapCapsLockToEscape = true;
    };

    # Power management - Not working
    # power= {
    #   sleep = {
    #       # Sleep options
    #     };
    # };
  };
}
