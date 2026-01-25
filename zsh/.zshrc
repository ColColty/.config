# ============================================================================
#                         Oh My Zsh Configuration
# ============================================================================
# A comprehensive zsh configuration with useful plugins and customizations
# ============================================================================

# Path to your oh-my-zsh installation
export ZSH="$HOME/.oh-my-zsh"

# ============================================================================
#                              Theme Settings
# ============================================================================

# Set name of the theme to load
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
ZSH_THEME="robbyrussell"

# Uncomment to use a powerline theme (requires powerline fonts)
# ZSH_THEME="agnoster"

# ============================================================================
#                           General Settings
# ============================================================================

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion.
# Case-sensitive completion must be off. _ and - will be interchangeable.
HYPHEN_INSENSITIVE="true"

# Uncomment one of the following lines to change the auto-update behavior
# zstyle ':omz:update' mode disabled  # disable automatic updates
# zstyle ':omz:update' mode auto      # update automatically without asking
zstyle ':omz:update' mode reminder    # just remind me to update when it's time

# Uncomment the following line to change how often to auto-update (in days).
zstyle ':omz:update' frequency 14

# Uncomment the following line if pasting URLs and other text is messed up.
# DISABLE_MAGIC_FUNCTIONS="true"

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# You can also set it to another string to have that shown instead of the default red dots.
COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
HIST_STAMPS="yyyy-mm-dd"

# ============================================================================
#                              Plugins
# ============================================================================
# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
#
# To install external plugins:
#   git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
#   git clone https://github.com/zsh-users/zsh-syntax-highlighting ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
#   git clone https://github.com/zsh-users/zsh-completions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-completions

plugins=(
    # === Core Utilities ===
    git                     # Git aliases and functions (ga, gc, gp, gst, etc.)
    gitfast                 # Faster git completion
    git-extras              # Extra git commands
    z                       # Jump to frequently used directories (z dirname)

    # === Enhanced Completions ===
    zsh-autosuggestions     # Fish-like autosuggestions (EXTERNAL - see install notes)
    zsh-syntax-highlighting # Fish-like syntax highlighting (EXTERNAL - see install notes)
    zsh-completions         # Additional completion definitions (EXTERNAL - see install notes)

    # === Directory Navigation ===
    colored-man-pages       # Colorize man pages
    command-not-found       # Suggest package for unknown commands
    copypath                # Copy current directory path to clipboard
    copyfile                # Copy file contents to clipboard
    dirhistory              # Navigate directory history with Alt+arrows

    # === Development Tools ===
    docker                  # Docker aliases and completions
    docker-compose          # Docker Compose completions
    npm                     # npm completions and aliases
    node                    # Node.js completions
    yarn                    # Yarn completions
    python                  # Python aliases (pyfind, pyclean, pygrep)
    pip                     # pip completions and aliases
    golang                  # Go aliases and completions
    rust                    # Rust/Cargo completions

    # === Cloud & DevOps ===
    kubectl                 # Kubernetes aliases and completions
    aws                     # AWS CLI completions
    terraform               # Terraform completions
    helm                    # Helm completions

    # === Utilities ===
    sudo                    # Press ESC twice to prepend sudo
    history                 # History aliases (h, hs, hsi)
    encode64                # Base64 encode/decode (encode64, decode64)
    jsontools               # JSON prettifier (pp_json, is_json)
    urltools                # URL encode/decode (urlencode, urldecode)
    web-search              # Search from terminal (google, bing, ddg)

    # === macOS Specific (comment out on Linux) ===
    macos                   # macOS utilities (ofd, pfd, quick-look)
    brew                    # Homebrew aliases and completions

    # === Fuzzy Finding ===
    fzf                     # Fuzzy finder integration
)

# ============================================================================
#                         Load Oh My Zsh
# ============================================================================

source $ZSH/oh-my-zsh.sh

# ============================================================================
#                         Environment Variables
# ============================================================================

# Preferred editor for local and remote sessions
if [[ -n $SSH_CONNECTION ]]; then
    export EDITOR='vim'
else
    export EDITOR='nvim'
fi

# Set language environment
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

# History settings
export HISTSIZE=50000
export SAVEHIST=50000
export HISTFILE=~/.zsh_history

# ============================================================================
#                              PATH Configuration
# ============================================================================

# Add common paths
typeset -U path  # Ensure unique entries
path=(
    $HOME/bin
    $HOME/.local/bin
    /usr/local/bin
    /usr/local/sbin
    $path
)

# Homebrew (macOS)
if [[ -f "/opt/homebrew/bin/brew" ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
elif [[ -f "/usr/local/bin/brew" ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
fi

# Go
export GOPATH="$HOME/go"
path=($GOPATH/bin $path)

# Rust/Cargo
if [[ -d "$HOME/.cargo/bin" ]]; then
    path=($HOME/.cargo/bin $path)
fi

# Node Version Manager (nvm)
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

# pnpm
export PNPM_HOME="$HOME/Library/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac

# Python (pyenv)
if command -v pyenv &> /dev/null; then
    export PYENV_ROOT="$HOME/.pyenv"
    path=($PYENV_ROOT/bin $path)
    eval "$(pyenv init -)"
fi

# ============================================================================
#                              direnv Support
# ============================================================================
# direnv allows project-specific environment variables via .envrc files

if command -v direnv &> /dev/null; then
    eval "$(direnv hook zsh)"
fi

# ============================================================================
#                              FZF Configuration
# ============================================================================

# FZF settings
export FZF_DEFAULT_OPTS="
    --height 40%
    --layout=reverse
    --border
    --inline-info
    --color=bg+:#313244,bg:#1e1e2e,spinner:#f5e0dc,hl:#f38ba8
    --color=fg:#cdd6f4,header:#f38ba8,info:#cba6f7,pointer:#f5e0dc
    --color=marker:#f5e0dc,fg+:#cdd6f4,prompt:#cba6f7,hl+:#f38ba8
"

# Use fd for FZF if available (faster than find)
if command -v fd &> /dev/null; then
    export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
    export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
    export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git'
fi

# FZF key bindings (if installed via package manager)
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# ============================================================================
#                              Aliases
# ============================================================================

# === Navigation ===
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias .....='cd ../../../..'
alias ~='cd ~'
alias -- -='cd -'

# === List Files ===
if command -v eza &> /dev/null; then
    alias ls='eza --icons'
    alias ll='eza -la --icons --git'
    alias la='eza -a --icons'
    alias lt='eza --tree --icons --level=2'
    alias lta='eza --tree --icons -a --level=2'
else
    alias ll='ls -lahF'
    alias la='ls -A'
    alias l='ls -CF'
fi

# === File Operations ===
alias cp='cp -iv'
alias mv='mv -iv'
alias rm='rm -iv'
alias mkdir='mkdir -pv'

# === Git Shortcuts (beyond oh-my-zsh defaults) ===
alias g='git'
alias gs='git status -sb'
alias glog='git log --oneline --decorate --graph'
alias glogall='git log --oneline --decorate --graph --all'
alias gd='git diff'
alias gds='git diff --staged'
alias gco='git checkout'
alias gcob='git checkout -b'
alias gaa='git add --all'
alias gcm='git commit -m'
alias gca='git commit --amend'
alias gp='git push'
alias gpf='git push --force-with-lease'
alias gpu='git push -u origin HEAD'
alias gl='git pull'
alias gf='git fetch --all --prune'
alias grb='git rebase'
alias grbi='git rebase -i'
alias gst='git stash'
alias gstp='git stash pop'
alias gwt='git worktree'

# === Docker ===
alias d='docker'
alias dc='docker compose'
alias dps='docker ps'
alias dpsa='docker ps -a'
alias di='docker images'
alias dex='docker exec -it'
alias dlog='docker logs -f'
alias dprune='docker system prune -af'

# === Kubernetes ===
alias k='kubectl'
alias kgp='kubectl get pods'
alias kgs='kubectl get services'
alias kgd='kubectl get deployments'
alias kga='kubectl get all'
alias kd='kubectl describe'
alias kl='kubectl logs -f'
alias kex='kubectl exec -it'
alias kctx='kubectx'
alias kns='kubens'

# === Editors ===
alias v='nvim'
alias vim='nvim'
alias vi='nvim'

# === Utility ===
alias c='clear'
alias h='history'
alias j='jobs -l'
alias path='echo -e ${PATH//:/\\n}'
alias now='date +"%Y-%m-%d %H:%M:%S"'
alias week='date +%V'
alias myip='curl -s https://api.ipify.org && echo'
alias localip="ipconfig getifaddr en0 2>/dev/null || hostname -I | awk '{print \$1}'"
alias ports='netstat -tulanp 2>/dev/null || lsof -iTCP -sTCP:LISTEN -P'
alias reload='source ~/.zshrc'
alias zshconfig='${EDITOR:-nvim} ~/.zshrc'

# === Networking ===
alias ping='ping -c 5'
alias fastping='ping -c 100 -s.2'
alias wget='wget -c'

# === Development ===
alias py='python3'
alias python='python3'
alias pip='pip3'
alias serve='python3 -m http.server 8000'
alias nr='npm run'
alias nrd='npm run dev'
alias nrb='npm run build'
alias nrt='npm run test'

# === tmux ===
alias t='tmux'
alias ta='tmux attach -t'
alias tn='tmux new -s'
alias tl='tmux list-sessions'
alias tk='tmux kill-session -t'
alias tka='tmux kill-server'

# ============================================================================
#                              Functions
# ============================================================================

# Create a new directory and cd into it
mkcd() {
    mkdir -p "$1" && cd "$1"
}

# Extract any archive
extract() {
    if [ -f "$1" ]; then
        case "$1" in
            *.tar.bz2)   tar xjf "$1"     ;;
            *.tar.gz)    tar xzf "$1"     ;;
            *.tar.xz)    tar xJf "$1"     ;;
            *.bz2)       bunzip2 "$1"     ;;
            *.rar)       unrar x "$1"     ;;
            *.gz)        gunzip "$1"      ;;
            *.tar)       tar xf "$1"      ;;
            *.tbz2)      tar xjf "$1"     ;;
            *.tgz)       tar xzf "$1"     ;;
            *.zip)       unzip "$1"       ;;
            *.Z)         uncompress "$1"  ;;
            *.7z)        7z x "$1"        ;;
            *)           echo "'$1' cannot be extracted via extract()" ;;
        esac
    else
        echo "'$1' is not a valid file"
    fi
}

# Quick find file
ff() {
    find . -type f -iname "*$1*"
}

# Quick find directory
fd() {
    find . -type d -iname "*$1*"
}

# Git worktree helper - list all worktrees
gwl() {
    git worktree list
}

# Open GitHub repo in browser (macOS)
ghopen() {
    local url=$(git remote get-url origin 2>/dev/null)
    if [[ -z "$url" ]]; then
        echo "Not a git repository or no remote origin"
        return 1
    fi
    url=${url/git@github.com:/https://github.com/}
    url=${url%.git}
    open "$url" 2>/dev/null || xdg-open "$url" 2>/dev/null
}

# Kill process on port
killport() {
    if [ -z "$1" ]; then
        echo "Usage: killport <port>"
        return 1
    fi
    lsof -ti:"$1" | xargs kill -9 2>/dev/null || echo "No process on port $1"
}

# Search for text in files
search() {
    grep -rn "$1" . --include="$2"
}

# Weather in terminal
weather() {
    curl -s "wttr.in/${1:-}"
}

# Cheat.sh - command line cheat sheets
cheat() {
    curl -s "cheat.sh/$1"
}

# ============================================================================
#                           Zsh Options
# ============================================================================

# History options
setopt EXTENDED_HISTORY          # Write timestamps to history
setopt HIST_EXPIRE_DUPS_FIRST    # Expire duplicate entries first
setopt HIST_IGNORE_DUPS          # Don't record consecutive duplicates
setopt HIST_IGNORE_ALL_DUPS      # Remove older duplicates
setopt HIST_FIND_NO_DUPS         # Don't display duplicates in search
setopt HIST_IGNORE_SPACE         # Don't record entries starting with space
setopt HIST_SAVE_NO_DUPS         # Don't write duplicates
setopt SHARE_HISTORY             # Share history between sessions
setopt INC_APPEND_HISTORY        # Add commands immediately

# Directory options
setopt AUTO_CD                   # cd by typing directory name
setopt AUTO_PUSHD                # Push directories onto stack
setopt PUSHD_IGNORE_DUPS         # Don't push duplicates
setopt PUSHD_SILENT              # Don't print directory stack

# Completion options
setopt ALWAYS_TO_END             # Move cursor to end after completion
setopt AUTO_MENU                 # Show completion menu on tab
setopt COMPLETE_IN_WORD          # Complete from both ends
setopt MENU_COMPLETE             # Insert first match immediately

# Globbing options
setopt EXTENDED_GLOB             # Extended globbing
setopt GLOB_DOTS                 # Include dotfiles in globbing

# ============================================================================
#                        Completion Styling
# ============================================================================

# Case-insensitive completion
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'

# Colorize completions
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"

# Menu selection
zstyle ':completion:*' menu select

# Group completions
zstyle ':completion:*' group-name ''
zstyle ':completion:*:descriptions' format '%F{yellow}-- %d --%f'

# ============================================================================
#                        Key Bindings
# ============================================================================

# Use emacs key bindings (or set to -v for vim)
bindkey -e

# Better history search
bindkey '^[[A' history-search-backward
bindkey '^[[B' history-search-forward

# Word navigation
bindkey '^[[1;5C' forward-word     # Ctrl+Right
bindkey '^[[1;5D' backward-word    # Ctrl+Left

# Delete word
bindkey '^H' backward-kill-word    # Ctrl+Backspace
bindkey '^[[3;5~' kill-word        # Ctrl+Delete

# ============================================================================
#                        Autosuggestions Config
# ============================================================================

# Customize autosuggestions (if plugin is loaded)
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=#666666'
ZSH_AUTOSUGGEST_STRATEGY=(history completion)
ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=20

# ============================================================================
#                        Syntax Highlighting Config
# ============================================================================

# Customize syntax highlighting (if plugin is loaded)
typeset -A ZSH_HIGHLIGHT_STYLES
ZSH_HIGHLIGHT_STYLES[command]='fg=green,bold'
ZSH_HIGHLIGHT_STYLES[builtin]='fg=green,bold'
ZSH_HIGHLIGHT_STYLES[alias]='fg=green,bold'
ZSH_HIGHLIGHT_STYLES[function]='fg=green,bold'
ZSH_HIGHLIGHT_STYLES[path]='fg=cyan,underline'
ZSH_HIGHLIGHT_STYLES[unknown-token]='fg=red,bold'

# ============================================================================
#                        Local Configuration
# ============================================================================

# Load local configuration if it exists (for machine-specific settings)
[[ -f ~/.zshrc.local ]] && source ~/.zshrc.local

# Load work configuration if it exists
[[ -f ~/.zshrc.work ]] && source ~/.zshrc.work

# ============================================================================
#                        Startup Messages
# ============================================================================

# Uncomment to show a welcome message
# echo "Welcome back, $(whoami)!"
# echo "Today is $(date '+%A, %B %d, %Y')"
