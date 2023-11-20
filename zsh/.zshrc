if [[ "$(uname -s)" = "Darwin" ]]; then
    export HOMEBREW_NO_ANALYTICS=1
    export PATH=$HOME/bin:/usr/local/bin:$PATH
    export GOPATH=/Users/xiao/Dev/go
    export PATH=$PATH:$GOPATH/bin    
    export ZSH="$HOME/.oh-my-zsh"
    alias surge="cd /Users/xiao/Library/Mobile Documents/iCloud~com~nssurge~inc/Documents"
    alias airport="/System/Library/PrivateFrameworks/Apple80211.framework/Versions/Current/Resources/airport"
    alias sublime="open -a Sublime\ Text"
    alias surge-cli="/Applications/Surge.app/Contents/Applications/surge-cli"
    alias bru="brew update && brew upgrade; brew cleanup"
    alias dev="cd ~/SynologyDrive/Dev"
    export LDFLAGS="-L/usr/local/opt/libffi/lib"
    export PKG_CONFIG_PATH="/usr/local/opt/libffi/lib/pkgconfig"
    ZSH_THEME='agnoster'
    if [[ -f /usr/bin/arch && $(/usr/bin/arch) == "arm64" ]]; then
    	export PATH=/opt/homebrew/bin:$PATH
    	source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh
    	source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
        alias x86="arch -x86_64"
        alias arm="arch -arm64"
    else
    	source /usr/local/share/zsh-autosuggestions/zsh-autosuggestions.zsh
    	source /usr/local/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
    fi
elif [[ "$(uname -s)" = "Linux" ]]; then
    export ZSH="$HOME/.oh-my-zsh"
    export GOPATH=/home/xiao/dev/go
    export PATH=$PATH:$GOPATH/bin    
    curl -s --socks5 127.0.0.1:1080 ifconfig.co > /dev/null
    if [[ $? == 0 ]]; then
        export http_proxy=socks5://127.0.0.1:1080
        export https_proxy=socks5://127.0.0.1:1080
    fi
    if [[ -f /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]]; then 
        source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
    fi
    if [[ -f /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.plugin.zsh ]]; then
        source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.plugin.zsh
    fi
    if uname -r | grep -q 'WSL'; then
        ZSH_THEME="agnoster"
    else
        ZSH_THEME="robbyrussell"
    fi
fi
export TERM="xterm-256color"
DEFAULT_USER=`whoami`
export EDITOR='nvim'
export FZF_DEFAULT_OPTS='--height 40% --layout=reverse --border'
alias pjson="python3 -m json.tool"

# Zsh
alias rzsh="source ~/.zshrc"
DISABLE_UPDATE_PROMPT=true

alias vim="nvim"
alias vi="nvim"
# Persist sshfs
alias sshfsp="sshfs -o reconnect,ServerAliveInterval=15,ServerAliveCountMax=3"
#alias ssf="sh -c $(history | grep ssh | grep @ | awk '{$1=$2=$3=""; print $0}' | fzf)"
#alias killf="ps -ax | fzf | awk '{print $1}' | xargs kill"
alias jqs="jq --sort-keys"

# Git
alias gpr="git pull --rebase"

#
# Uncomment the following line to use case-sensitive completion
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion. Case
# sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment the following line to disable bi-weekly auto-update checks.
# DISABLE_AUTO_UPDATE="true"

# Uncomment the following line to change how often to auto-update (in days).
# export UPDATE_ZSH_DAYS=13

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# The optional three formats: "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load? (plugins can be found in ~/.oh-my-zsh/plugins/*)
# Custom plugins may be added to ~/.oh-my-zsh/custom/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(
    ansible
    aws
    colored-man-pages
    colorize
    docker 
    docker-compose
    extract
    fzf
    git
    nmap
    rsync
    rust
    tmux 
    z 
)
# TMUX Settings
ZSH_TMUX_AUTOSTART_ONCE="true"
ZSH_TMUX_CONNECTING="true"

# User configuration

# export PATH="/usr/bin:/bin:/usr/sbin:/sbin:$PATH"
# export MANPATH="/usr/local/man:$MANPATH"

fpath+=${ZSH_CUSTOM:-${ZSH:-~/.oh-my-zsh}/custom}/plugins/zsh-completions/src
source $ZSH/oh-my-zsh.sh

# You may need to manually set your language environment
export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
# if [[ -n $SSH_CONNECTION ]]; then
#   export EDITOR='vim'
# else
#   export EDITOR='mvim'
# fi

# Compilation flags
# export ARCHFLAGS="-arch x86_64"

# ssh
# export SSH_KEY_PATH="~/.ssh/dsa_id"

# Set personal aliases, overriding those provided by oh-my-zsh libs,
# plugins, and themes. Aliases can be placed here, though oh-my-zsh
# users are encouraged to define aliases within the ZSH_CUSTOM folder.
# For a full list of active aliases, run `alias`.
#
# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"

if [ -f ~/.zshrc-local ]; then
    source ~/.zshrc-local
fi

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
export PATH=$PATH:/Users/xiao/.spicetify

if command -v ranger > /dev/null 2>&1; then
    unalias ll
    alias ll="ranger"
else
    alias ll="ls -alh"
fi

[ -f ~/.inshellisense/key-bindings.zsh ] && source ~/.inshellisense/key-bindings.zsh
