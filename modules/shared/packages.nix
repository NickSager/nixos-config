{ pkgs, ... }:

# TODO: Review packages
with pkgs; [
  # General packages for development and system management
  act
  alacritty
  # aspell
  atuin
  # aspellDicts.en
  # bash-completion
  bat
  btop
  # coreutils
  # difftastic
  du-dust
  eza
  gcc
  # git-filter-repo
  killall
  neofetch
  openssh
  pandoc
  R
  sqlite
  starship
  syncthing
  wget
  zip
  uv
  zoxide

  # Encryption and security tools
  _1password-cli
  age
  age-plugin-yubikey
  gnupg
  libfido2

  # Communication tools
  # discord
  firefox
  # slack
  # zoom-us

  # Cloud-related tools and SDKs
  docker
  docker-compose
  # awscli2 - marked broken Mar 22
  # flyctl
  # google-cloud-sdk
  # go
  # gopls
  # ngrok
  # ssm-session-manager-plugin
  # terraform
  # terraform-ls
  # tflint

  # Media-related packages
  emacs-all-the-icons-fonts
  imagemagick
  dejavu_fonts
  ffmpeg
  fd
  font-awesome
  glow
  hack-font
  # jpegoptim
  meslo-lgs-nf
  noto-fonts
  noto-fonts-emoji
  # pngquant

  # PHP
  # php82
  # php82Packages.composer
  # php82Packages.php-cs-fixer
  # php82Extensions.xdebug
  # php82Packages.deployer
  # phpunit

  # Node.js development tools
  # nodePackages.live-server
  # nodePackages.nodemon
  # nodePackages.prettier
  # nodePackages.npm
  # nodejs

  # Source code management, Git, GitHub tools
  gh
  lazygit

  # Text and terminal utilities
  bc
  htop
  # hunspell
  fzf
  iftop
  jetbrains-mono
  # jetbrains.phpstorm
  jq
  ripgrep
  # thefuck
  # tree
  tmux
  unrar
  unzip
  vscode
  # vscodium
  # zsh-powerlevel10k

  # Python packages
  black
  poetry
  python3
  virtualenv
]
