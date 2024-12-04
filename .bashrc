#!/usr/bin/env bash
#  shellcheck disable=SC1091
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2006-06-28 23:25:09 +0100 (Wed, 28 Jun 2006)
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
#                     BASH - Heavily Customized Environment
# ============================================================================ #

# Sources thousands of lines of Bash code written over the course of ~15+ years
# some of which is now found in this GitHub repo's .bash.d/*.sh

# ============================================================================ #
#
# put this at the top of your ~/.bashrc to inherit the goodness here (assuming you've checked out this repo to ~/github/bash-tools):
#
#   if [ -f ~/github/bash-tools/.bashrc ]; then
#       . ~/github/bash-tools/.bashrc
#   fi
#
# ============================================================================ #


# Use with PS4 further down + profile-bash.pl (still in private repos) for performance profiling this bashrc
#set -x

# If not running interactively, don't do anything:
[ -z "${PS1:-}" ] && return

[ -n "${PERLBREW_PERL:-}" ] && return

# Another alternative
#case $- in
#   *i*) ;;
#     *) return 0;;
#esac

# Another variation
#if [[ $- != *i* ]] ; then
#    # Shell is non-interactive.  Be done now!
#    return
#fi

# ============================================================================ #

# after cleanshell, not even $HOME is set, this messes up things that base off $HOME, like SDKman
if [ -z "${HOME:-}" ]; then
    export HOME=~
fi

bash_tools="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# needed to inherit by things like vim script execution from within files using libraries rooted at this location
export bash_tools

# shellcheck disable=SC1090,SC1091
. "$bash_tools/.bash.d/os_detection.sh"

# enable color support for ls
if [ "$TERM" != "dumb" ] && \
   ! is_mac; then
    eval "$(dircolors -b)"
fi

# shut up Mac, Bash still rocks
export BASH_SILENCE_DEPRECATION_WARNING=1

# ============================================================================ #

# technically should get called only for new login shells
#[ -f /etc/profile     ] && . /etc/profile
[ -f /etc/bash/bashrc ] && . /etc/bash/bashrc
[ -f /etc/bashrc      ] && . /etc/bashrc

[ -f /etc/bash_completion ] && . /etc/bash_completion

[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

# shellcheck disable=SC1090,SC1091
[ -f "$HOME/.aliases" ] && source "$HOME/.aliases"

# ============================================================================ #

# SECURITY TO STOP STUFF BEING WRITTEN TO DISK
#unset HISTFILE
#unset HISTFILESIZE
export HISTSIZE=50000
export HISTFILESIZE=50000

rmhist(){ history -d "$1"; }
histrm(){ rmhist "$1"; }
histrmlast(){ history -d "$(history | tail -n 2 | head -n 1 | awk '{print $1}')"; }

# This adds a time format of "YYYY-mm-dd hh:mm:ss  command" to the bash history
export HISTTIMEFORMAT="%F %T  "

# stop logging duplicate successive commands to history
#HISTCONTROL=ignoredups:ignorespace
HISTCONTROL=ignoredups

# Neat trick "[ \t]*" to exclude any command by just prefixing it with a space. Fast way of going stealth for pw entering on cli
# & here means any duplicate patterns, others are simple things like built-ins and ls and stuff you don't need history for
#export HISTIGNORE="[ \t]*:&:ls:[bf]g:exit"

# append rather than overwrite history
shopt -s histappend

# check window size and update $LINES and $COLUMNS after each command
shopt -s checkwinsize

shopt -s cdspell

# prevent core dumps which can leak sensitive information
ulimit -c 0

# tighten permissions except for root where library installations become inaccessible to my user account
if [ $EUID = 0 ]; then
    umask 0022
else
    # caused no end of problems when doing sudo command which retained 0077 and broke library access for user accounts
    #umask 0077
    umask 0022
fi

# make less more friendly for non-text input files, see lesspipe(1)
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

# ============================================================================ #

sudo=sudo
if [ $EUID -eq 0 ]; then
    # used throughout .bash.d/*.sh
    # shellcheck disable=SC2034
    sudo=""
fi

# shellcheck disable=SC1090,SC1091
type add_PATH &>/dev/null || . "$bash_tools/.bash.d/paths.sh"

# ============================================================================ #

# want this to fail is there is no match because we should always have local .bash.d/*.sh in this repo
# shopt -s nullglob
for src in "$bash_tools/.bash.d/"*.sh; do
    # shellcheck disable=SC1090,SC1091
    . "$src"
done
# shopt -u nullglob

# added by travis gem - should be in ~/.bashrc so not needed to duplicate here
#[ -f /Users/hari.sekhon/.travis/travis.sh ] && source /Users/hari.sekhon/.travis/travis.sh

# shellcheck disable=SC1090,SC1091
[ -f "$HOME/.bashrc.local" ] && . "$HOME/.bashrc.local"
if [ -d "$HOME/.bash.d" ]; then
    shopt -s nullglob
    for src in "$HOME/.bash.d/"*.sh; do
        # shellcheck disable=SC1090,SC1091
        . "$src"
    done
    shopt -u nullglob
fi
if [ -d "$HOME/.bash.autocomplete.d" ]; then
    shopt -s nullglob
    for src in "$HOME/.bash.autocomplete.d/"*.sh; do
        # shellcheck disable=SC1090,SC1091
        . "$src"
    done
    shopt -u nullglob
fi
