{
  description = "General Purpose Configuration for macOS, Linux, and NixOS";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    home-manager.url = "github:nix-community/home-manager";
    agenix.url = "github:ryantm/agenix";
    # claude-desktop = {
    #   url = "github:k3d3/claude-desktop-linux-flake";
    #   inputs = { 
    #     nixpkgs.follows = "nixpkgs";
    #     flake-utils.follows = "flake-utils";
    #   };
    # };
    darwin = {
      url = "github:LnL7/nix-darwin/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-homebrew = {
      url = "github:zhaofengli-wip/nix-homebrew";
    };
    homebrew-bundle = {
      url = "github:homebrew/homebrew-bundle";
      flake = false;
    };
    homebrew-core = {
      url = "github:homebrew/homebrew-core";
      flake = false;
    };
    homebrew-cask = {
      url = "github:homebrew/homebrew-cask";
      flake = false;
    };
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    #secrets = {
    #  url = "git+ssh://git@github.com/nicksager/nix-secrets.git";
    #  flake = false;
    #};

    # Obsidian daily work tracking setup by thsvaugh.
    # Uncomment to fetch templates/scripts/prompts directly from the repo
    # instead of maintaining local copies under modules/shared/config/obsidian/.
    # Update with: nix flake update obsidian-daily-setup
    #obsidian-daily-setup = {
    #  url = "git+ssh://git@code.amazon.com/packages/Thsvaugh-ObsidianDailySetup";
    #  flake = false;
    #};
    emacs-overlay = {
      url = "github:nix-community/emacs-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    niri-flake = {
      url = "github:sodiboo/niri-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs = { self, darwin, nix-homebrew, homebrew-bundle, homebrew-core, homebrew-cask, home-manager, nixpkgs, flake-utils, disko, agenix, emacs-overlay, niri-flake } @inputs:
    let
      profile = "work"; # "work" or "personal"
      user = if profile == "work" then "nsager" else "nick";
      linuxSystems = [ "x86_64-linux" "aarch64-linux" ];
      darwinSystems = [ "aarch64-darwin" "x86_64-darwin" ];
      forAllSystems = f: nixpkgs.lib.genAttrs (linuxSystems ++ darwinSystems) f;
      devShell = system: let pkgs = nixpkgs.legacyPackages.${system}; in {
        default = with pkgs; mkShell {
          nativeBuildInputs = with pkgs; [ bashInteractive git age age-plugin-yubikey ];
          shellHook = with pkgs; ''
            export EDITOR=vim
          '';
        };
      };
      mkApp = scriptName: system: {
        type = "app";
        program = "${(nixpkgs.legacyPackages.${system}.writeScriptBin scriptName ''
          #!/usr/bin/env bash
          PATH=${nixpkgs.legacyPackages.${system}.git}/bin:$PATH
          echo "Running ${scriptName} for ${system}"
          exec ${self}/apps/${system}/${scriptName}
        '')}/bin/${scriptName}";
      };
      mkLinuxApps = system: {
        "apply" = mkApp "apply" system;
        "build" = mkApp "build" system;
        "build-switch" = mkApp "build-switch" system;
        "copy-keys" = mkApp "copy-keys" system;
        "create-keys" = mkApp "create-keys" system;
        "check-keys" = mkApp "check-keys" system;
        "install" = mkApp "install" system;
        "install-with-secrets" = mkApp "install-with-secrets" system;
      };
      mkDarwinApps = system: {
        "apply" = mkApp "apply" system;
        "build" = mkApp "build" system;
        "build-switch" = mkApp "build-switch" system;
        "copy-keys" = mkApp "copy-keys" system;
        "create-keys" = mkApp "create-keys" system;
        "check-keys" = mkApp "check-keys" system;
        "rollback" = mkApp "rollback" system;
      };
    in
    {
      templates = {
        starter = {
          path = ./templates/starter;
          description = "Starter configuration";
        };
        starter-with-secrets = {
          path = ./templates/starter-with-secrets;
          description = "Starter configuration with secrets";
        };
      };
      devShells = forAllSystems devShell;
      apps = nixpkgs.lib.genAttrs linuxSystems mkLinuxApps // nixpkgs.lib.genAttrs darwinSystems mkDarwinApps;
      darwinConfigurations = nixpkgs.lib.genAttrs darwinSystems (system:
        darwin.lib.darwinSystem {
          inherit system;
          specialArgs = inputs // { inherit user profile; };
          modules = [
            home-manager.darwinModules.home-manager
            nix-homebrew.darwinModules.nix-homebrew
            {
              nix-homebrew = {
                inherit user;
                enable = true;
                taps = {
                  "homebrew/homebrew-core" = homebrew-core;
                  "homebrew/homebrew-cask" = homebrew-cask;
                  "homebrew/homebrew-bundle" = homebrew-bundle;
                };
                mutableTaps = false;
                autoMigrate = true;
              };
            }
            # Symlink app files for dock
            ./modules/darwin/nix-apps.nix

            ./hosts/darwin
          ];
        }
      );
      nixosConfigurations = nixpkgs.lib.genAttrs linuxSystems (system:
        nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = inputs // { inherit user profile; };
          modules = [
            disko.nixosModules.disko
            niri-flake.nixosModules.niri
            home-manager.nixosModules.home-manager {
              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;
                extraSpecialArgs = { inherit profile; };
                users.${user} = { config, pkgs, lib, ... }:
                  import ./modules/nixos/home-manager.nix { inherit config pkgs lib inputs user; };
              };
            }
            ./hosts/nixos
          ];
        }
      );
      # Linux (non-NixOS) configs.
      homeConfigurations = nixpkgs.lib.genAttrs linuxSystems (system:
        home-manager.lib.homeManagerConfiguration {
          pkgs = nixpkgs.legacyPackages.${system};
          extraSpecialArgs = inputs // { inherit user profile; };
          modules = [
            ./hosts/linux
          ];
        }
      );
    };
}
