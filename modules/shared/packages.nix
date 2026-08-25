{ pkgs, ... }:
let
  myPython = pkgs.python3.withPackages (ps: with ps; [
    pip
    rich
    virtualenv
  ]);

  # texlive.combine {scheme-full} is deprecated (removal targeted for 27.05);
  # texliveFull is the same scheme-full closure via the non-deprecated path.
  myTexlive = pkgs.texliveFull;

  myFonts = import ./fonts.nix { inherit pkgs; };
in
with pkgs; [
  # A
  act # Run Github actions locally
  age # File encryption tool
  age-plugin-yubikey # YubiKey plugin for age encryption
  alacritty # GPU-accelerated terminal emulator
  # aspell # Spell checker
  # aspellDicts.en # English dictionary for aspell
  atuin # Fancy ctrl-r

  # B
  bash-completion # Bash completion scripts
  bat # Cat clone with syntax highlighting
  bc # Calculator
  btop # System monitor and process viewer

  # C
  # claude-code # Installed natively via ../shared/ai-agents.nix (self-updates)
  # codex # Installed natively via ../shared/ai-agents.nix (self-updates)
  # coreutils # Basic file/text/shell utilities

  # D
  direnv # Environment variable management per directory
  difftastic # Structural diff tool
  # discord # Discord
  # docker
  # docker-compose
  dust # Disk usage analyzer

  # E
  eza # Better ls

  # F
  fd # Fast find alternative
  ffmpeg # Multimedia framework
  # firefox # Browser
  fzf # Fuzzy finder

  # G
  gcc # GNU Compiler Collection
  gh # GitHub CLI
  glow # Markdown renderer for terminal
  gnupg # GNU Privacy Guard
  go # Go programming language
  golangci-lint # Go linter aggregator
  gotools # Go tools (goimports, godoc, etc.)
  gopls # Go language server
  delve # Go debugger

  # H
  htop # Interactive process viewer
  # hunspell # Spell checker

  # I
  iftop # Network bandwidth monitor
  imagemagick # Image manipulation toolkit

  # J
  # jetbrains.phpstorm # PHP IDE
  # jpegoptim # JPEG optimizer
  jq # JSON processor

  # K
  killall # Kill processes by name

  # L
  lazygit # Git TUI
  libfido2 # FIDO2 library

  # M
  mosh # Mobile shell (SSH alternative with roaming support)
  # myPHP # Custom PHP with extensions
  myPython # Custom Python with packages

  # N
  ncurses # Required: terminfo database for tmux/alacritty TERM resolution
  # neofetch removed (unmaintained); use fastfetch if needed
  # ngrok # Secure tunneling service
  nodejs # Node.js runtime + npm/npx
  # nodePackages.live-server # Development server with live reload
  # nodePackages.nodemon # Node.js file watcher
  # nodePackages.npm # Node package manager
  # (hiPrio nodePackages.prettier) # Code formatter

  # O
  # obsidian - managed declaratively via programs.obsidian in modules/shared/obsidian.nix

  # P
  pandoc # Document converter
  # php82Packages.composer # PHP dependency manager
  # php82Packages.deployer # PHP deployment tool
  # php82Packages.php-cs-fixer # PHP code style fixer
  # phpunit # PHP testing framework
  # pngquant # PNG compression tool
  poetry # Package manager for python

  # R
  ripgrep # Fast text search tool
  # R # Stats language
  rustup

  # S
  # slack # Team communication app
  starship # Prompt in Rust
  # syncthing # Syncing directories

  # T
  # terraform # Infrastructure as code tool
  # terraform-ls # Terraform language server
  # tflint # Terraform linter
  # myTexlive # TeX Live, 3+ Gb
  tmux # Terminal multiplexer
  tree # Directory tree viewer

  # U
  unrar # RAR archive extractor
  unzip # ZIP archive extractor
  uv # Python package installer

  # V
  # vscode
  # vscodium

  # W
  wget # File downloader

  # Z
  zip # ZIP archive creator
  # zsh-powerlevel10k # Zsh theme
  # zoom-us # Zoom
  zoxide # Better cd
] ++ myFonts
