{ config, pkgs, emacs-overlay, herdr, ... }:

{

  nixpkgs = {
    config = {
      allowUnfree = true;
      allowInsecure = false;
    };

    overlays =
      # Apply each overlay found in the /overlays directory
      let path = ../../overlays; in with builtins;
      map (n: import (path + ("/" + n)))
          (filter (n: match ".*\.nix" n != null ||
                      pathExists (path + ("/" + n + "/default.nix")))
                  (attrNames (readDir path)))

      ++ [
        emacs-overlay.overlays.default
        herdr.overlays.default
      ];
  };
}
