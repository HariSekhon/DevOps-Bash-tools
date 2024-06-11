#!/usr/bin/env bash
#  shellcheck disable=SC1091
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2006-06-28 23:25:09 +0100 (Wed, 28 Jun 2006)
#  (forked from .bashrc)
#
#  https://github.com/HariSekhon/DevOps-Bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/HariSekhon
#

# ============================================================================ #
#                                     Z S H
# ============================================================================ #

# https://wiki.archlinux.org/index.php/Zsh

# goes horribly wrong - too much advanced bash
#if [[ -e ~/.bashrc  ]]; then
#    emulate sh -c 'source ~/.bashrc'
#fi

autoload -Uz compinit promptinit
compinit  # completes ssh/scp/sftp hostnames as long as HashKnownHosts not set in ~/.ssh/config
promptinit

# prompt -l - list themes
# prompt -p - preview themes
#prompt suse

# install Oh-My-ZSH
# sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

# custom themes:
# mkdir ~/.zprompts
# fpath=("$HOME/.zprompts" "$fpath[@]")

# uniq all items in $PATH and $path array
typeset -U PATH path
path=("$HOME/.local/bin" "$HOME/bin" "$path[@]")
export PATH

# autocompletion with an arrow-key driven interface - tab twice to enable
zstyle ':completion:*' menu select

# autocompletions with sudo
# allows zsh completion scripts run commands with sudo privileges - do not enable if using untrusted autocompletion scripts!!
#zstyle ':completion::complete:*' gain-privileges 1

# ============================================================================ #
#                                S e t t i n g s
# ============================================================================ #

# compatible style with other shells
#set -o AUTO_CD
# casse insensitive, underscores stripped
setopt AUTO_CD

setopt COMPLETE_ALIASES

setopt CORRECT
export SPROMPT="Correct %R to %r? [Yes, No, Abort, Edit] "

autoload U colors && colors

# expand wilcard expansion on unquoted variables like Bash
setopt GLOB_SUBST

export PATH="$PATH:/opt/homebrew/bin/"

# ============================================================================ #
#                                   Oh-My-ZSH
# ============================================================================ #

# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:/usr/local/bin:$PATH

# Path to your oh-my-zsh installation.
export ZSH="/Users/hari.sekhon/.oh-my-zsh"

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time oh-my-zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
ZSH_THEME="robbyrussell"

# also messed up
#ZSH_THEME="agnoster"

# messes up both Terminal and iTerm2 from both brew and git cloned installations
#if [ -f /usr/local/opt/powerlevel9k/powerlevel9k.zsh-theme ]; then
#    source /usr/local/opt/powerlevel9k/powerlevel9k.zsh-theme
#fi
#
# Oh-My-ZSH ~/.oh-my-zsh/custom/themes/powerlevel9k
#ZSH_THEME="powerlevel9k/powerlevel9k"

# Set list of themes to pick from when loading at random
# Setting this variable when ZSH_THEME=random will cause zsh to load
# a theme from this variable instead of looking in ~/.oh-my-zsh/themes/
# If set to an empty array, this variable will have no effect.
# ZSH_THEME_RANDOM_CANDIDATES=( "robbyrussell" "agnoster" )

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion.
# Case-sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment the following line to disable bi-weekly auto-update checks.
# DISABLE_AUTO_UPDATE="true"

# Uncomment the following line to automatically update without prompting.
# DISABLE_UPDATE_PROMPT="true"

# Uncomment the following line to change how often to auto-update (in days).
# export UPDATE_ZSH_DAYS=13

# Uncomment the following line if pasting URLs and other text is messed up.
# DISABLE_MAGIC_FUNCTIONS=true

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
# You can set one of the optional three formats:
# "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# or set a custom format using the strftime function format specifications,
# see 'man strftime' for details.
# HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load?
# Standard plugins can be found in ~/.oh-my-zsh/plugins/*
# Custom plugins may be added to ~/.oh-my-zsh/custom/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(git)

source $ZSH/oh-my-zsh.sh

# User configuration

# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
# if [[ -n $SSH_CONNECTION ]]; then
#   export EDITOR='vim'
# else
#   export EDITOR='mvim'
# fi

# Compilation flags
# export ARCHFLAGS="-arch x86_64"

# Set personal aliases, overriding those provided by oh-my-zsh libs,
# plugins, and themes. Aliases can be placed here, though oh-my-zsh
# users are encouraged to define aliases within the ZSH_CUSTOM folder.
# For a full list of active aliases, run `alias`.
#
# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"

# ============================================================================ #

# Lines configured by zsh-newuser-install
HISTFILE=~/.histfile
HISTSIZE=1000
SAVEHIST=1000
setopt appendhistory autocd extendedglob nomatch notify
unsetopt beep
bindkey -e
# End of lines configured by zsh-newuser-install
# The following lines were added by compinstall
zstyle :compinstall filename '/home/hari/.zshrc'
autoload -Uz compinit
compinit
# End of lines added by compinstall

# added by travis gem - Travis is legacy now, don't bother with this
#[ -f /Users/hari/.travis/travis.sh ] && source /Users/hari/.travis/travis.sh

if type -P direnv &>/dev/null; then
    eval "$(direnv hook zsh)"
fi

autoload -U +X bashcompinit && bashcompinit
complete -o nospace -C /Users/hari/bin/terraform terraform
complete -o nospace -C /Users/hari/bin/terraform tf

complete -o nospace -C /usr/local/bin/terragrunt terragrunt

#THIS MUST BE AT THE END OF THE FILE FOR SDKMAN TO WORK!!!
export SDKMAN_DIR="/Users/hari/.sdkman"
[[ -s "/Users/hari/.sdkman/bin/sdkman-init.sh" ]] && source "/Users/hari/.sdkman/bin/sdkman-init.sh"
