# modules/darwin/nix-apps.nix
{ config, pkgs, lib, ... }:

let
  # Build an environment that only exposes /Applications from all system packages
  nixAppsEnv = pkgs.buildEnv {
    name = "darwin-nix-apps";
    paths = config.environment.systemPackages;
    pathsToLink = [ "/Applications" ];
  };
in
{
  # Create /Applications/Nix Apps pointing at that environment
  system.activationScripts.nixApps = {
    text = ''
      echo "Linking Nix GUI apps into /Applications/Nix Apps..."
      mkdir -p /Applications
      rm -rf "/Applications/Nix Apps"
      ln -sfn ${nixAppsEnv}/Applications "/Applications/Nix Apps"
    '';
  };
}
