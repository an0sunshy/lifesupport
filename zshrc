# Path to your oh-my-zsh installation.
if [[ `uname` == "Linux" ]]; then
        export ZSH=/home/xiao/.oh-my-zsh
        DEFAULT_USER="xiao"
        export GOPATH=/home/xiao/Dropbox/Dev/go
        source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh 
        xset b off
elif [[ `uname` == "Darwin" ]]; then
        export ZSH=/Users/xiao/.oh-my-zsh
        DEFAULT_USER="xiao"
        source /usr/local/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
        export GOPATH=/Users/xiao/Dropbox/Dev/go
        export https_proxy=http://127.0.0.1:6152
        export http_proxy=http://127.0.0.1:6152
        alias surge="cd /Users/xiao/Library/Mobile\ Documents/iCloud~run~surge/Documents"
        alias airport="/System/Library/PrivateFrameworks/Apple80211.framework/Versions/Current/Resources/airport"
        alias sublime="open -a Sublime\ Text"
        alias notesdir="/Users/xiao/Dropbox/Document/MyNotes"
        alias surge-cli="/Applications/Surge.app/Contents/Applications/surge-cli"
        alias bru="brew update && brew upgrade && brew cleanup"
        alias pip="/usr/local/bin/pip2.7"
        alias python="/usr/local/bin/python2"
fi
export PATH=$PATH:$GOPATH/bin
export EDITOR='nvim'
alias dev="cd ~/Dropbox/Dev"
alias py3="python3"
alias py="python"
alias g="git"
alias rzsh="source ~/.zshrc"
alias vim="nvim"

# Set name of the theme to load.
# Look in ~/.oh-my-zsh/themes/
# Optionally, if you set this to "random", it'll load a random theme each
# time that oh-my-zsh is loaded.
ZSH_THEME="agnoster"

# Uncomment the following line to use case-sensitive completion.
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
plugins=(git z fzf zsh-syntax-highlighting)

# User configuration

# export PATH="/usr/bin:/bin:/usr/sbin:/sbin:$PATH"
# export MANPATH="/usr/local/man:$MANPATH"

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

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
