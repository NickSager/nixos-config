{ config, pkgs, lib, ... }:

let name = "Nick Sager";
    user = "nick";
    email = "sager.nick@gmail.com"; in
{

  neovim = {
    enable = true;
    extraConfig = ''
    '';
  };

  direnv = {
      enable = true;
      enableZshIntegration = true;
      nix-direnv.enable = true;
    };

  zsh = {
    enable = true;
    autocd = false;
    autosuggestion = {
        enable = true;
    };
    cdpath = [ "~/.local/share/src" ];
    oh-my-zsh = {
      enable = true;
      plugins = [ "git" "thefuck" "starship" "poetry" ];
      theme = "robbyrussell";
    };
    sessionVariables = {
      # Environment Variables
    };
    shellAliases = {
      cat="bat";
      cd="z";
      cl="clear";
      fk="thefuck";
      lg="lazygit";
      nm="nmap -sC -sV -oN nmap";
      v="nvim";

      # Eza
      # ls="eza --color=always --long --git --no-filesize --icons=always --no-time --no-user --no-permissions";
      ls="eza --git --icons=always";
      l="eza -l --icons --git -a";
      lt="eza --tree --level=2 --long --icons --git";
      ltree="eza --tree --level=2  --icons --git";
    };
    syntaxHighlighting = {
      enable = true;
    };
    initExtra = '' #initExtraFirst for beginning in zshrc
      # ---- ALIASES -----

      # Set Work Directory
      export Work="$HOME/Documents/Workspace/"

      # ---- FZF -----

      # Set up fzf key bindings and fuzzy completion
      eval "$(fzf --zsh)"

      # -- Use fd instead of fzf --
      export FZF_DEFAULT_COMMAND="fd --hidden --strip-cwd-prefix --exclude .git"
      export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
      export FZF_ALT_C_COMMAND="fd --type=d --hidden --strip-cwd-prefix --exclude .git"

      # Use fd (https://github.com/sharkdp/fd) for listing path candidates.
      # - The first argument to the function ($1) is the base path to start traversal
      # - See the source code (completion.{bash,zsh}) for the details.
      _fzf_compgen_path() {
        fd --hidden --exclude .git . "$1"
      }

      # Use fd to generate the list for directory completion
      _fzf_compgen_dir() {
        fd --type=d --hidden --exclude .git . "$1"
      }

      show_file_or_dir_preview="if [ -d {} ]; then eza --tree --color=always {} | head -200; else bat -n --color=always --line-range :500 {}; fi"

      export FZF_CTRL_T_OPTS="--preview '$show_file_or_dir_preview'"
      export FZF_ALT_C_OPTS="--preview 'eza --tree --color=always {} | head -200'"

      # Advanced customization of fzf options via _fzf_comprun function
      # - The first argument to the function is the name of the command.
      # - You should make sure to pass the rest of the arguments to fzf.
      _fzf_comprun() {
        local command=$1
        shift

        case "$command" in
          cd)           fzf --preview 'eza --tree --color=always {} | head -200' "$@" ;;
          export|unset) fzf --preview 'echo {}' "$@" ;;
          ssh)          fzf --preview 'dig {}'                   "$@" ;;
          *)            fzf --preview "$show_file_or_dir_preview" "$@" ;;
        esac
      }


      export XDG_CONFIG_HOME="/Users/nick/.config"

      # ---- MISC -----
      export STARSHIP_CONFIG=~/.config/starship.toml
      eval "$(starship init zsh)"

      eval "$(zoxide init zsh)"
      eval "$(atuin init zsh --disable-up-arrow)"
      # eval "$(direnv hook zsh)"

      # Pipx Path
      export PATH="$PATH:/Users/nick/.local/bin"
      eval "$(/opt/homebrew/bin/brew shellenv)"

      # Remove history data we don't want to see
      export HISTIGNORE="pwd:ls:cd"
    '';
  };

  git = {
    enable = true;
    ignores = [ "*.swp" ];
    userName = name;
    userEmail = email;
    lfs = {
      enable = true;
    };
    extraConfig = {
      init.defaultBranch = "main";
      core = {
	    editor = "vim";
        autocrlf = "input";
      };
      # commit.gpgsign = true; # Uncomment to use secrets, else system figures out
      pull.rebase = true;
      rebase.autoStash = true;
    };
  };

  vim = {
    enable = true;
    plugins = with pkgs.vimPlugins; [ vim-airline vim-airline-themes copilot-vim vim-startify vim-tmux-navigator ];
    settings = { ignorecase = true; };
    extraConfig = ''
      "" General
      set number
      set history=1000
      set nocompatible
      set modelines=0
      set encoding=utf-8
      set scrolloff=3
      set showmode
      set showcmd
      set hidden
      set wildmenu
      set wildmode=list:longest
      set cursorline
      set ttyfast
      set nowrap
      set ruler
      set backspace=indent,eol,start
      set laststatus=2
      set clipboard=autoselect

      " Dir stuff
      set nobackup
      set nowritebackup
      set noswapfile
      set backupdir=~/.config/vim/backups
      set directory=~/.config/vim/swap

      " Relative line numbers for easy movement
      set relativenumber
      set rnu

      "" Whitespace rules
      set tabstop=8
      set shiftwidth=2
      set softtabstop=2
      set expandtab

      "" Searching
      set incsearch
      set gdefault

      "" Statusbar
      set nocompatible " Disable vi-compatibility
      set laststatus=2 " Always show the statusline
      let g:airline_theme='bubblegum'
      let g:airline_powerline_fonts = 1

      "" Local keys and such
      let mapleader=","
      let maplocalleader=" "

      "" Change cursor on mode
      :autocmd InsertEnter * set cul
      :autocmd InsertLeave * set nocul

      "" File-type highlighting and configuration
      syntax on
      filetype on
      filetype plugin on
      filetype indent on

      "" Paste from clipboard
      nnoremap <Leader>, "+gP

      "" Copy from clipboard
      xnoremap <Leader>. "+y

      "" Move cursor by display lines when wrapping
      nnoremap j gj
      nnoremap k gk

      "" Map leader-q to quit out of window
      nnoremap <leader>q :q<cr>

      "" Move around split
      nnoremap <C-h> <C-w>h
      nnoremap <C-j> <C-w>j
      nnoremap <C-k> <C-w>k
      nnoremap <C-l> <C-w>l

      "" Easier to yank entire line
      nnoremap Y y$

      "" Move buffers
      nnoremap <tab> :bnext<cr>
      nnoremap <S-tab> :bprev<cr>

      "" Like a boss, sudo AFTER opening the file to write
      cmap w!! w !sudo tee % >/dev/null

      let g:startify_lists = [
        \ { 'type': 'dir',       'header': ['   Current Directory '. getcwd()] },
        \ { 'type': 'sessions',  'header': ['   Sessions']       },
        \ { 'type': 'bookmarks', 'header': ['   Bookmarks']      }
        \ ]

      let g:startify_bookmarks = [
        \ '~/.local/share/src',
        \ ]

      let g:airline_theme='bubblegum'
      let g:airline_powerline_fonts = 1
      '';
     };

  alacritty = {
    enable = true;
    settings = {
      cursor = {
        style = "Block";
      };

      window = {
        opacity = 1.0;
        padding = {
          x = 6;
          y = 6;
        };
        decorations = "buttonless"; # full, buttonless, None
      };

      font = {
        normal = {
          family = "MesloLGS NF";
          style = "Regular";
        };
        size = lib.mkMerge [
          (lib.mkIf pkgs.stdenv.hostPlatform.isLinux 10)
          (lib.mkIf pkgs.stdenv.hostPlatform.isDarwin 11)
        ];
      };

      colors = {
        primary = {
          background = "0x1f2528";
          foreground = "0xc0c5ce";
        };

        normal = {
          black = "0x1f2528";
          red = "0xec5f67";
          green = "0x99c794";
          yellow = "0xfac863";
          blue = "0x6699cc";
          magenta = "0xc594c5";
          cyan = "0x5fb3b3";
          white = "0xc0c5ce";
        };

        bright = {
          black = "0x65737e";
          red = "0xec5f67";
          green = "0x99c794";
          yellow = "0xfac863";
          blue = "0x6699cc";
          magenta = "0xc594c5";
          cyan = "0x5fb3b3";
          white = "0xd8dee9";
        };
      };
    };
  };

  ssh = {
    enable = true;
    includes = [
      (lib.mkIf pkgs.stdenv.hostPlatform.isLinux
        "/home/${user}/.ssh/config_external"
      )
      (lib.mkIf pkgs.stdenv.hostPlatform.isDarwin
        "/Users/${user}/.ssh/config_external"
      )
    ];
    matchBlocks = {
      "github.com" = {
        identitiesOnly = true;
        identityFile = [
          (lib.mkIf pkgs.stdenv.hostPlatform.isLinux
            "/home/${user}/.ssh/id_github"
          )
          (lib.mkIf pkgs.stdenv.hostPlatform.isDarwin
            "/Users/${user}/.ssh/id_github"
          )
        ];
      };
    };
  };

  # TODO: Re-sourcing? Tmux config (:source-file ~/.config/tmux/tmux.conf)
  tmux = {
    enable = true;
    plugins = with pkgs.tmuxPlugins; [
      vim-tmux-navigator
      # sensible
      yank
      prefix-highlight
      resurrect
      continuum
      catppuccin
      tmux-fzf # prefix-F
    ];
    terminal = "screen-256color";
    prefix = "C-Space";
    escapeTime = 0;
    historyLimit = 100000;
    extraConfig = ''
      # Color Options
      # set-option -g default-terminal 'screen-256color'
      set -ga terminal-overrides ",xterm-256color:Tc"

      unbind C-b
      # set -g prefix C-Space
      set -g focus-events on           # Remove Vim mode delays
      set -g mouse on
      set -g base-index 1              # start indexing windows at 1 instead of 0
      set -g pane-base-index 1
      set -g detach-on-destroy off     # don't exit from tmux when closing a session
      set -g escape-time 0             # zero-out escape time delay
      set -g history-limit 1000000     # increase history size (from 2,000)
      set -g renumber-windows on       # renumber all windows when any window is closed
      set -g set-clipboard on          # use system clipboard
      set -g status-position top       # macOS / darwin style
      setw -g mode-keys vi
      set -g pane-active-border-style 'fg=magenta,bg=default'
      set -g pane-border-style 'fg=brightblack,bg=default'
      bind C-Space send-prefix
      bind R source-file ~/.config/tmux/tmux.conf # Reset tmux

      # Resurrect (prefix-^-s and prefix-^-r)
      # set -g @resurrect-dir '/Users/nick/.cache/tmux/resurrect'
      set -g @resurrect-capture-pane-contents 'on'
      set -g @resurrect-pane-contents-area 'visible'
      set -g @continuum-save-interval '5' # minutes
      set -g @continuum-restore 'off' # restore tmux on tmux start
      set -g @resurrect-strategy-nvim 'session'

      # Use Alt-arrow keys without prefix key to switch panes
      bind -n M-Left select-pane -L
      bind -n M-Right select-pane -R
      bind -n M-Up select-pane -U
      bind -n M-Down select-pane -D

      # Shift arrow to switch windows
      bind -n S-Left  previous-window
      bind -n S-Right next-window

      # Shift Alt vim keys to switch windows
      bind -n M-H previous-window
      bind -n M-L next-window

      # VI keybindings
      bind-key -T copy-mode-vi v send-keys -X begin-selection
      bind-key -T copy-mode-vi C-v send-keys -X rectangle-toggle
      bind-key -T copy-mode-vi y send-keys -X copy-selection-and-cancel

      bind '_' split-window -v -c "#{pane_current_path}"
      bind '|' split-window -h -c "#{pane_current_path}"

      # Themes: latte, frappe, macchiato, mocha
      set -g @catppuccin_flavour 'mocha'

      # Catpuccin setup
      set -g @catppuccin_window_left_separator ""
      set -g @catppuccin_window_right_separator " "
      set -g @catppuccin_window_middle_separator " █"
      set -g @catppuccin_window_number_position "right"
      set -g @catppuccin_window_default_fill "number"
      set -g @catppuccin_window_default_text "#W"
      set -g @catppuccin_window_current_fill "number"
      set -g @catppuccin_window_current_text "#W#{?window_zoomed_flag,(),}"
      set -g @catppuccin_status_modules_right "directory meetings date_time"
      set -g @catppuccin_status_modules_left "session"
      set -g @catppuccin_status_left_separator  " "
      set -g @catppuccin_status_right_separator " "
      set -g @catppuccin_status_right_separator_inverse "no"
      set -g @catppuccin_status_fill "icon"
      set -g @catppuccin_status_connect_separator "no"
      set -g @catppuccin_directory_text "#{b:pane_current_path}"
      set -g @catppuccin_date_time_text "%H:%M"
      '';
    };
}
