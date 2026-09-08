{
  description = "General Purpose Configuration for macOS, Linux, and NixOS";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
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
    gammons-tap = {
      url = "github:gammons/homebrew-tap";
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

    # obsidian-mind agent vault, pinned to an upstream release tag.
    # Copied into ~/Documents/Notes by modules/shared/obsidian.nix.
    # Upgrade: bump the tag, `nix flake update obsidian-mind`, read the
    # upstream CHANGELOG, rebuild.
    obsidian-mind = {
      url = "github:breferrari/obsidian-mind/v8.3.6";
      flake = false;
    };

    # pstack skill set (Lauren Tan / poteto) from Cursor's plugins repo,
    # pinned to a commit. Copied into the shared skills root by
    # modules/shared/skills.nix.
    pstack = {
      url = "github:cursor/plugins/46125561306434d8a1d7745d540d8932ab0cd2a2";
      flake = false;
    };

    herdr = {
      url = "github:herdrdev/herdr/v0.8.2";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Matt Pocock's reusable coding skills. Keep this source independent from
    # pstack so either set can be updated or removed without touching the
    # other's managed files.
    pocock = {
      url = "github:mattpocock/skills/6654f6b60cd9d5be8b54c6fafe44346dabeb3b76";
      flake = false;
    };
    emacs-overlay = {
      url = "github:nix-community/emacs-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    niri-flake = {
      url = "github:sodiboo/niri-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs = { self, darwin, nix-homebrew, homebrew-bundle, homebrew-core, homebrew-cask, gammons-tap, home-manager, nixpkgs, flake-utils, disko, agenix, emacs-overlay, niri-flake, obsidian-mind, pstack, herdr, pocock } @inputs:
    let
      profile = "personal"; # "work" or "personal"
      user = if profile == "work" then "nicholas.sager" else "nick";
      linuxSystems = [ "x86_64-linux" "aarch64-linux" ];
      darwinSystems = [ "aarch64-darwin" ];
      nixosSystems = [ "x86_64-linux" ];
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
        meta.description = "Run ${scriptName} for ${system}";
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
                  "gammons/homebrew-tap" = gammons-tap;
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
      nixosConfigurations = nixpkgs.lib.genAttrs nixosSystems (system:
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
                extraSpecialArgs = { inherit profile obsidian-mind pstack pocock; };
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
