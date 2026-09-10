# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This is a Nix flake-based configuration for managing macOS (nix-darwin), NixOS, and generic Linux systems. It uses home-manager for user-level configuration and supports both Apple Silicon and Intel architectures.

## Common Commands

```bash
# Build without applying (to verify changes work)
nix run .#build

# Build and switch to new configuration
nix run .#build-switch

# Rollback to previous generation (macOS only)
nix run .#rollback

# Update flake inputs
nix flake update

# Update Homebrew cask/formula definitions (replaces `brew update`, which is
# disabled by mutableTaps = false). Then build-switch upgrades installed casks.
nix flake update homebrew-core homebrew-cask homebrew-bundle
```

**Important:** Flakes only see files in the Git index. Run `git add -N .` before building. To enroll ignored local certificates without staging their contents, run `git add -f -N -- local-certs/*.pem`. Never use `git add .`, `git add -A`, or `git commit -a` because these commands can stage certificate contents.

## Architecture

### Module Composition Pattern

The flake passes all inputs plus `user` and `profile` to every system module via `specialArgs`:
```nix
specialArgs = inputs // { inherit user profile; };
```

Each platform host (in `hosts/`) imports and composes modules from `modules/`. The key composition pattern uses attribute set merge (`//`) for home-manager programs:
```nix
programs = {} // import ../shared/home-manager.nix { inherit config pkgs lib; };
```

Files are layered with `lib.mkMerge`:
```nix
file = lib.mkMerge [
  sharedFiles                            # From let binding
  (import ../shared/files.nix {...})     # Cross-platform dotfiles
  (import ./files.nix {...})             # Platform-specific files
];
```

Packages use `pkgs.callPackage` which auto-passes `pkgs` and `lib`:
```nix
home.packages = pkgs.callPackage ./packages.nix {};
```

### Directory Structure

- `flake.nix` - Entry point; selects the `personal` profile and the `nick` user by default
- `hosts/` - Platform entry points that import and compose modules
- `modules/shared/` - Cross-platform config (packages, home-manager programs, fonts, dotfiles)
- `modules/darwin/` - macOS-specific (homebrew casks, dock management, nix-apps symlinks)
- `modules/nixos/` - NixOS-specific (Niri Wayland compositor, disk config, greetd, services)
- `modules/linux/` - Generic Linux home-manager config
- `apps/{system}/` - Platform-specific shell scripts run via `nix run .#<command>`
- `overlays/` - Auto-loaded Nix overlays (drop `.nix` files here; discovered by `modules/shared/default.nix`)

### Key Files for Common Changes

| Want to change... | Edit this file |
|---|---|
| CLI tools / packages (all platforms) | `modules/shared/packages.nix` |
| macOS GUI apps (Homebrew casks) | `modules/darwin/casks.nix` |
| macOS-only packages | `modules/darwin/packages.nix` |
| Shell config (zsh, git, vim, etc.) | `modules/shared/home-manager.nix` |
| Neovim, Emacs, starship, Claude settings | `modules/shared/files.nix` |
| macOS dock items | `modules/darwin/home-manager.nix` (look for `local.dock.entries`) |
| NixOS compositor/window mgr (Niri) | `modules/nixos/home-manager.nix` |
| NixOS system services | `hosts/nixos/default.nix` |
| Disk layout (NixOS) | `modules/nixos/disk-config.nix` |

### Platform Differences

- **macOS**: Uses nix-darwin + nix-homebrew for casks. Dock is declaratively managed via dockutil. Apps symlinked via `modules/darwin/nix-apps.nix`.
- **NixOS**: Full Wayland desktop with Niri compositor, Waybar, Fuzzel launcher, Mako notifications, greetd display manager. Uses disko for disk management.
- **Generic Linux** (`homeConfigurations`): Home-manager only, no system-level config. Uses the same profile-selected user as the system configurations.

### Secrets

Uses agenix for encrypted secrets. Secrets are stored in a separate private repo (currently commented out in flake inputs). Platform-specific secret mounting in `modules/*/secrets.nix`.

## Workflow

1. Edit relevant `.nix` files in `modules/` or `hosts/`
2. Run `git add -N .` so flakes see new files without staging their contents
3. Run `nix run .#build` to verify
4. Run `nix run .#build-switch` to apply
