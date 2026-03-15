{ pkgs }:
with pkgs;
let shared-packages = import ../shared/packages.nix { inherit pkgs; }; in
shared-packages ++ [

  _1password-gui # Password manager
  
  apple-cursor # macOS-style cursor theme
  
  cider-appimage # Apple Music client
  
  cliphist # Clipboard history manager for Wayland

  brlaser # Printer driver

  discord # Voice and text chat

  gimp # Image editor
  google-chrome # Web browser
  
  hyprpicker # Wayland color picker

  imv # Lightweight Wayland image viewer
  
  pavucontrol # Pulse audio controls
  playerctl # Control media players from command line

  qmk # Keyboard firmware toolkit


  unixtools.ifconfig # Network interface configuration
  unixtools.netstat # Network statistics

  vlc # Media player

  # Wayland-specific tools for Niri
  grim # Screenshot tool for Wayland
  slurp # Area selection for screenshots
  swappy # Screenshot annotation tool
  swaylock # Screen locker for Wayland
  swayidle # Idle management daemon
  kanshi # Dynamic display configuration
  wdisplays # GUI display configurator for Wayland
  swaybg # Wallpaper daemon for Wayland
  
  nautilus # GNOME file browser with excellent Wayland support
  
  yubikey-agent # Yubikey SSH agent
  pinentry-qt # GPG pinentry

  zathura # PDF viewer
]
