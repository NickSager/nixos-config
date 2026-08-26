# Apps
The scripts in this directory back the `nix run .#<command>` apps declared in
the root `flake.nix`.

The main commands are:

- `nix run .#build` builds the current platform without activating it.
- `nix run .#build-switch` builds and activates the current platform.
- `nix run .#rollback` rolls macOS back to the previous generation.
- The key-management commands support the optional agenix setup.

Each architecture has its own script directory because the flake selects apps
using the current Nix system.
