# Nix system configuration

Personal Nix configuration for macOS, NixOS, and standalone Linux systems.
The active profile is selected in `flake.nix`; it currently uses the personal
profile and the `nick` user.

## Layout

- `flake.nix` defines inputs, systems, Home Manager configurations, and apps.
- `hosts/` contains the macOS, NixOS, and standalone Linux entry points.
- `modules/shared/` contains packages, shell and editor configuration, the
  Obsidian vault setup, and shared coding-agent configuration.
- `modules/darwin/` contains macOS defaults, Homebrew casks, Dock entries, and
  application linking.
- `modules/nixos/` contains the `felix` hardware and desktop configuration.
- `modules/linux/` contains standalone Home Manager configuration.
- `apps/` contains the scripts exposed through `nix run`.
- `overlays/` contains automatically loaded Nixpkgs overlays.

## macOS installation

Install the Xcode Command Line Tools:

```sh
xcode-select --install
```

Install upstream Nix in multi-user mode:

```sh
curl --proto '=https' --tlsv1.2 -L https://nixos.org/nix/install | sh
```

Open a new terminal, clone this repository, and change into its directory.
Build the configuration before activating it. Pass the experimental-feature
flag only for the first build and switch; nix-darwin manages that setting after
activation.

```sh
git add .
nix --extra-experimental-features 'nix-command flakes' run .#build
nix --extra-experimental-features 'nix-command flakes' run .#build-switch
```

To provision the work profile, change `profile` in `flake.nix` to `"work"`.
The work profile uses the `nicholas.sager` user.

## Common commands

```sh
# Build without applying
git add .
nix run .#build

# Build and activate
git add .
nix run .#build-switch

# Roll back one macOS generation
nix run .#rollback

# Update all pinned inputs
nix flake update

# Refresh immutable Homebrew taps
nix flake update homebrew-core homebrew-cask homebrew-bundle
```

Flakes only include Git-tracked files. Stage new files before building.
See [the maintenance guide](docs/MAINTENANCE.md) for pinned obsidian-mind,
pstack, Pocock skill, and QMD updates.

## Platform notes

### macOS

nix-darwin manages system defaults and Home Manager. nix-homebrew manages the
Homebrew installation and immutable taps. Homebrew installs the small set of
casks in `modules/darwin/casks.nix`.

### NixOS

The NixOS configuration is hardware-specific to `felix`. It uses Niri,
Waybar, Fuzzel, Mako, greetd, PipeWire, and NetworkManager. Review disk UUIDs
and `modules/nixos/disk-config.nix` before using it on another machine.

### Standalone Linux

The `homeConfigurations` outputs apply the shared user environment without
managing the operating system.

## Agent and note configuration

Home Manager seeds one Obsidian and agent vault at `~/Documents/Notes` from a
pinned `obsidian-mind` input. It copies a fixed set of writable Obsidian
configuration files. User-created notes and workspace state remain user-owned;
pinned upstream entrypoints and documentation remain managed. Claude Code,
Codex, and Hermes share skills stored in the vault. Native agent installers for
Hermes, Claude Code, and Codex run once when their marker directories are
absent. After Hermes is provisioned, run `hermes setup` to select a provider.

## Secrets

Agenix modules and helper commands remain available, but the private secrets
input and platform secret modules are currently disabled.
