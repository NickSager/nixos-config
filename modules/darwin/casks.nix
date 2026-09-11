{ lib, profile ? "personal" }:

let
  allCasks = [
  # Utility Tools
  "caffeine" # Menu-bar utility to keep the Mac awake (no lid-closed support)
  "tailscale-app" # Tailscale macOS GUI and menu-bar client

  # Communication Tools
  "gammons/tap/slk" # Keyboard-driven terminal UI client for Slack
  "signal" # Signal Desktop
  "telegram" # Native Telegram for macOS client

  # Development Tools
  "docker-desktop" # Docker VM, daemon, CLI, and Compose plugin
  "soapui" # SOAP API testing and mock service tool

  # Browsers
  "firefox"

#   # Development Tools
#   "claude"
#   "insomnia"
#   "tableplus"
#   "ngrok"
#   "postico"
#   "visual-studio-code"
#   "wireshark-app"
#
#   # Communication Tools
#   "discord"
#   "loom"
#   "slack"
#   "telegram"
#   "zoom"
#
#   # Utility Tools
#   "appcleaner"
#   "syncthing-app"
#
#   # Entertainment Tools
#   "steam"
#   "vlc"
#
#   # Productivity Tools
#   "raycast"
#   "asana"
#
#   # Browsers
#   "google-chrome"
  ];
  workExcludedCasks = [
    "tailscale-app"
    "telegram"
  ];
in
lib.subtractLists (lib.optionals (profile == "work") workExcludedCasks) allCasks
