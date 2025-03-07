{ config, pkgs, lib, ... }:

let name = "Nick Sager";
    user = "nick";
    email = "sager.nick@gmail.com"; in
{

  direnv = {
      enable = true;
      enableZshIntegration = true;
      nix-direnv.enable = true;
    };

  # TODO: test zsh config
  zsh = {
    enable = true;
    autocd = false;
    cdpath = [ "~/.local/share/src" ];
      oh-my-zsh = {
      enable = true;
      plugins = [ "git" "thefuck" "zsh-autosuggestions" "zsh-syntax-highlighting" "starship" "poetry" ];
      theme = "robbyrussell";
    };
    plugins = [
      # {
      #     name = "powerlevel10k";
      #     src = pkgs.zsh-powerlevel10k;
      #     file = "share/zsh-powerlevel10k/powerlevel10k.zsh-theme";
      # }
      # {
      #     name = "powerlevel10k-config";
      #     src = lib.cleanSource ./config;
      #     file = "p10k.zsh";
      # }
    ];
    # TODO: Get rid of oh-my-zsh extras
    initExtraFirst = ''

      # If you come from bash you might have to change your $PATH.
      # export PATH=$HOME/bin:/usr/local/bin:$PATH

      # Path to your oh-my-zsh installation.
      export ZSH="$HOME/.oh-my-zsh"

      # Set name of the theme to load --- if set to "random", it will
      # load a random theme each time oh-my-zsh is loaded, in which case,
      # to know which specific one was loaded, run: echo $RANDOM_THEME
      # See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
      ZSH_THEME="robbyrussell"

      # Set list of themes to pick from when loading at random
      # Setting this variable when ZSH_THEME=random will cause zsh to load
      # a theme from this variable instead of looking in $ZSH/themes/
      # If set to an empty array, this variable will have no effect.
      # ZSH_THEME_RANDOM_CANDIDATES=( "robbyrussell" "agnoster" )

      # Uncomment the following line to use case-sensitive completion.
      # CASE_SENSITIVE="true"

      # Uncomment the following line to use hyphen-insensitive completion.
      # Case-sensitive completion must be off. _ and - will be interchangeable.
      # HYPHEN_INSENSITIVE="true"
      #
      # Uncomment one of the following lines to change the auto-update behavior
      # zstyle ':omz:update' mode disabled  # disable automatic updates
      # zstyle ':omz:update' mode auto      # update automatically without asking
      # zstyle ':omz:update' mode reminder  # just remind me to update when it's time

      # Uncomment the following line to change how often to auto-update (in days).
      # zstyle ':omz:update' frequency 13
      #
      # Uncomment the following line if pasting URLs and other text is messed up.
      # DISABLE_MAGIC_FUNCTIONS="true"
      #
      # Uncomment the following line to disable colors in ls.
      # DISABLE_LS_COLORS="true"
      #
      # Uncomment the following line to disable auto-setting terminal title.
      # DISABLE_AUTO_TITLE="true"
      #
      # Uncomment the following line to enable command auto-correction.
      # ENABLE_CORRECTION="true"
      #
      # Uncomment the following line to display red dots whilst waiting for completion.
      # You can also set it to another string to have that shown instead of the default red dots.
      # e.g. COMPLETION_WAITING_DOTS="%F{yellow}waiting...%f"
      # Caution: this setting can cause issues with multiline prompts in zsh < 5.7.1 (see #5765)
      # COMPLETION_WAITING_DOTS="true"
      #
      # Uncomment the following line if you want to disable marking untracked files
      # under VCS as dirty. This makes repository status check for large repositories
      # much, much faster.
      # DISABLE_UNTRACKED_FILES_DIRTY="true"
      #
      # Uncomment the following line if you want to change the command execution time
      # stamp shown in the history command output.
      # You can set one of the optional three formats:
      # "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
      # or set a custom format using the strftime function format specifications,
      # see 'man strftime' for details.
      # HIST_STAMPS="mm/dd/yyyy"
      #
      # Would you like to use another custom folder than $ZSH/custom?
      # ZSH_CUSTOM=/path/to/new-custom-folder
      #
      # Which plugins would you like to load?
      # Standard plugins can be found in $ZSH/plugins/
      # Custom plugins may be added to $ZSH_CUSTOM/plugins/
      # Example format: plugins=(rails git textmate ruby lighthouse)
      # Add wisely, as too many plugins slow down shell startup.
      # plugins=(git zsh-autosuggestions zsh-syntax-highlighting starship poetry)

      # source $ZSH/oh-my-zsh.sh

      # User configuration
      #
      # export MANPATH="/usr/local/man:$MANPATH"
      #
      # You may need to manually set your language environment
      # export LANG=en_US.UTF-8
      #
      # Preferred editor for local and remote sessions
      # if [[ -n $SSH_CONNECTION ]]; then
      #   export EDITOR='vim'
      # else
      #   export EDITOR='mvim'
      # fi
      #
      # Compilation flags
      # export ARCHFLAGS="-arch x86_64"
      #
      # Set personal aliases, overriding those provided by oh-my-zsh libs,
      # plugins, and themes. Aliases can be placed here, though oh-my-zsh
      # users are encouraged to define aliases within the ZSH_CUSTOM folder.
      # For a full list of active aliases, run `alias`.
      #
      # Example aliases
      # alias zshconfig="mate ~/.zshrc"
      # alias ohmyzsh="mate ~/.oh-my-zsh"
      # bindkey jj vi-cmd-mode
      alias cat="bat"
      alias cl='clear'
      alias nm="nmap -sC -sV -oN nmap"
      alias v="nvim"

      # Eza
      # alias ls="eza --color=always --long --git --no-filesize --icons=always --no-time --no-user --no-permissions"
      alias ls="eza --git --icons=always"
      alias l="eza -l --icons --git -a"
      alias lt="eza --tree --level=2 --long --icons --git"
      alias ltree="eza --tree --level=2  --icons --git"

      # Run Starship prompt
      export STARSHIP_CONFIG=~/.config/starship.toml
      eval "$(starship init zsh)"

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
      commit.gpgsign = true;
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
          x = 24;
          y = 24;
        };
      };

      font = {
        normal = {
          family = "MesloLGS NF";
          style = "Regular";
        };
        size = lib.mkMerge [
          (lib.mkIf pkgs.stdenv.hostPlatform.isLinux 10)
          (lib.mkIf pkgs.stdenv.hostPlatform.isDarwin 14)
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

  # TODO: Test Tmux config
  tmux = {
    enable = true;
    plugins = with pkgs.tmuxPlugins; [
      vim-tmux-navigator
      sensible
      yank
      prefix-highlight
      # {
      #   plugin = power-theme;
      #   extraConfig = ''
      #      set -g @tmux_power_theme 'gold'
      #   '';
      # }
      {
        plugin = resurrect; # Used by tmux-continuum

        # Use XDG data directory
        # https://github.com/tmux-plugins/tmux-resurrect/issues/348
        extraConfig = ''
          # set -g @resurrect-dir '/Users/nick/.cache/tmux/resurrect'
          set -g @resurrect-capture-pane-contents 'on'
          set -g @resurrect-pane-contents-area 'visible'
        '';
      }
      {
        plugin = continuum;
        extraConfig = ''
          set -g @continuum-restore 'on'
          set -g @continuum-save-interval '5' # minutes
        '';
      }
    ];
    terminal = "screen-256color";
    prefix = "C-Space";
    escapeTime = 10;
    historyLimit = 100000;
    extraConfig = ''
      # Color Options
      # set -s default-terminal "tmux-256color"
      # set -sa terminal-overrides ",xterm-256color:Tc"

      # set-option -g default-terminal 'screen-256color'
      # set-option -g terminal-overrides ',xterm-256color:RGB'

      # Remove Vim mode delays
      set -g focus-events on

      unbind C-b
      # set -g prefix C-Space
      set -g mouse on
      set -g base-index 1              # start indexing windows at 1 instead of 0
      set -g pane-base-index 1
      set -g detach-on-destroy off     # don't exit from tmux when closing a session
      set -g escape-time 0             # zero-out escape time delay
      set -g history-limit 1000000     # increase history size (from 2,000)
      set -g renumber-windows on       # renumber all windows when any window is closed
      set -g set-clipboard on          # use system clipboard
      set -g status-position top       # macOS / darwin style
      set -g default-terminal "${TERM}"
      setw -g mode-keys vi
      set -g pane-active-border-style 'fg=magenta,bg=default'
      set -g pane-border-style 'fg=brightblack,bg=default'
      bind C-Space send-prefix

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


      # set -g @plugin 'tmux-plugins/tpm'
      # set -g @plugin 'tmux-plugins/tmux-sensible'
      # set -g @plugin 'christoomey/vim-tmux-navigator'
      set -g @plugin 'catppuccin/tmux'
      set -g @plugin 'sainnhe/tmux-fzf' # prefix-F
      # set -g @plugin 'tmux-plugins/tmux-resurrect' # prefix-^-s save, prefix-^-r restore
      # set -g @plugin 'tmux-plugins/tmux-continuum'
      # set -g @plugin 'tmux-plugins/tmux-yank'

      # Themes: latte, frappe, macchiato, mocha
      set -g @catppuccin_flavour 'mocha'
      set -g @continuum-restore 'on' # restore tmux on tmux start
      set -g @resurrect-strategy-nvim 'session'

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

      # Not needed?
      # run '~/.config/tmux/plugins/tpm/tpm'

      # OLD From nixos config. Saved for reference
      # # Move around panes with vim-like bindings (h,j,k,l)
      # bind-key -n M-k select-pane -U
      # bind-key -n M-h select-pane -L
      # bind-key -n M-j select-pane -D
      # bind-key -n M-l select-pane -R
      #
      # # Smart pane switching with awareness of Vim splits.
      # # This is copy paste from https://github.com/christoomey/vim-tmux-navigator
      # is_vim="ps -o state= -o comm= -t '#{pane_tty}' \
      #   | grep -iqE '^[^TXZ ]+ +(\\S+\\/)?g?(view|n?vim?x?)(diff)?$'"
      # bind-key -n 'C-h' if-shell "$is_vim" 'send-keys C-h'  'select-pane -L'
      # bind-key -n 'C-j' if-shell "$is_vim" 'send-keys C-j'  'select-pane -D'
      # bind-key -n 'C-k' if-shell "$is_vim" 'send-keys C-k'  'select-pane -U'
      # bind-key -n 'C-l' if-shell "$is_vim" 'send-keys C-l'  'select-pane -R'
      # tmux_version='$(tmux -V | sed -En "s/^tmux ([0-9]+(.[0-9]+)?).*/\1/p")'
      # if-shell -b '[ "$(echo "$tmux_version < 3.0" | bc)" = 1 ]' \
      #   "bind-key -n 'C-\\' if-shell \"$is_vim\" 'send-keys C-\\'  'select-pane -l'"
      # if-shell -b '[ "$(echo "$tmux_version >= 3.0" | bc)" = 1 ]' \
      #   "bind-key -n 'C-\\' if-shell \"$is_vim\" 'send-keys C-\\\\'  'select-pane -l'"
      #
      # bind-key -T copy-mode-vi 'C-h' select-pane -L
      # bind-key -T copy-mode-vi 'C-j' select-pane -D
      # bind-key -T copy-mode-vi 'C-k' select-pane -U
      # bind-key -T copy-mode-vi 'C-l' select-pane -R
      # bind-key -T copy-mode-vi 'C-\' select-pane -l
      '';
    };
}
