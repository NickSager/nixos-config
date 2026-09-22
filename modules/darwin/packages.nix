{ pkgs }:

with pkgs;
let shared-packages = import ../shared/packages.nix { inherit pkgs; }; in
shared-packages ++ [
  # F
  fswatch # File change monitor

  # O
  (pkgs.callPackage ./omlx.nix {}) # Local model server for Apple Silicon

]
