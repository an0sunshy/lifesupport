#!/bin/zsh

# ============================================================================
# ENVIRONMENT DETECTION
# ============================================================================

OS_TYPE="$(uname -s)"

# Cache WSL detection to avoid repeated system calls
if [[ -z "$IS_WSL" && "$OS_TYPE" = "Linux" ]]; then
    export IS_WSL=$(uname -r | grep -q 'WSL' && echo "true" || echo "false")
fi

# ============================================================================
# CORE ENVIRONMENT VARIABLES
# ============================================================================

export LANG=en_US.UTF-8
export DEFAULT_USER=$USER
export EDITOR='nvim'

# ============================================================================
# ZSH CONFIGURATION
# ============================================================================

export ZSH="$HOME/.oh-my-zsh"

# Enable Oh My Zsh auto update only on Mondays
if [[ $(date +%u) -eq 1 ]]; then
    DISABLE_UPDATE_PROMPT=false
else
    DISABLE_UPDATE_PROMPT=true
fi

HIST_STAMPS="mm/dd/yyyy"

# ============================================================================
# ZSH PLUGINS
# ============================================================================

plugins=(
    ansible
    colored-man-pages
    docker 
    docker-compose
    extract
    fzf
    git
    rsync
    rust
    timer
    uv
    z 
)

# Timer plugin configuration
TIMER_FORMAT='[%d]'
TIMER_PRECISION=2

# ============================================================================
# PLATFORM-SPECIFIC CONFIGURATION
# ============================================================================

if [[ "$OS_TYPE" = "Darwin" ]]; then
    # macOS Configuration
    ZSH_THEME='agnoster'
    
    # Homebrew
    export HOMEBREW_NO_ANALYTICS=1
    
    # PATH configuration
    export PATH=$HOME/bin:$HOME/.local/bin:/opt/homebrew/bin:/usr/local/bin:$PATH
    export PATH=$PATH:/Users/xiao/.spicetify
    
    # Go configuration
    export GOPATH=/Users/xiao/dev/go
    export PATH=$PATH:$GOPATH/bin
    
    source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh
    source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
    
elif [[ "$OS_TYPE" = "Linux" ]]; then
    # Linux Configuration
    if [[ "$IS_WSL" = "true" ]]; then
        ZSH_THEME="agnoster"
    else
        ZSH_THEME="robbyrussell"
    fi
    
    # Go configuration
    export GOPATH=/home/xiao/dev/go
    export PATH=$PATH:$GOPATH/bin
    
    # ZSH plugins (system paths)
    if [[ -f /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]]; then 
        source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
    fi
    if [[ -f /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.plugin.zsh ]]; then
        source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.plugin.zsh
    fi
fi

# ============================================================================
# OH-MY-ZSH INITIALIZATION
# ============================================================================

fpath+=${ZSH_CUSTOM:-${ZSH:-~/.oh-my-zsh}/custom}/plugins/zsh-completions/src
source $ZSH/oh-my-zsh.sh

# ============================================================================
# TOOL-SPECIFIC CONFIGURATION
# ============================================================================

# FZF
export FZF_DEFAULT_OPTS='--height 40% --layout=reverse --border'
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# ============================================================================
# ALIASES
# ============================================================================

# System aliases
alias vim="nvim"
alias vi="nvim"
alias rzsh="source ~/.zshrc"

# Utility aliases
alias pjson="python3 -m json.tool"
alias jqs="jq --sort-keys"

# Network/SSH aliases
alias sshfsp="sshfs -o reconnect,ServerAliveInterval=15,ServerAliveCountMax=3"

# Git aliases
alias gpr="git pull --rebase"

# macOS-specific aliases
if [[ "$OS_TYPE" = "Darwin" ]]; then
    alias surge="cd /Users/xiao/Library/Mobile Documents/iCloud~com~nssurge~inc/Documents"
    alias airport="/System/Library/PrivateFrameworks/Apple80211.framework/Versions/Current/Resources/airport"
    alias sublime="open -a Sublime\ Text"
    alias surge-cli="/Applications/Surge.app/Contents/Applications/surge-cli"
    alias bru="brew update && brew upgrade; brew cleanup"
    alias dev="cd ~/SynologyDrive/Dev"
    alias arm="arch -arm64"
fi

# Conditional aliases based on available tools
if command -v ranger > /dev/null 2>&1; then
    unalias ll
    alias ll="ranger"
else
    alias ll="ls -alh"
fi

alias ccyolo="claude --dangerously-skip-permissions"
alias oc="openclaw" 

# ============================================================================
# CUSTOM FUNCTIONS
# ============================================================================

getHostname() {
    if [[ -z "$1" ]]; then
        echo "Usage: getHostname <hostname>"
        return 1
    fi
    
    rg "$1" ~/.ssh/config -A 5 | rg -o "Hostname\s+(\S+)" --replace '$1'
}

# ============================================================================
# LOCAL CONFIGURATION
# ============================================================================

# Source local configuration if it exists
if [ -f ~/.zshrc-local ]; then
    source ~/.zshrc-local
fi

# Source local environment if it exists
if [ -f "$HOME/.local/bin/env" ]; then
    . "$HOME/.local/bin/env"
fi

if command -v mise &> /dev/null; then
    eval "$(mise activate zsh)"
fi
