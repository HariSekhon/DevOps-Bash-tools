#!/usr/bin/env bash
#  shellcheck disable=SC1091
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2006-06-28 23:25:09 +0100 (Wed, 28 Jun 2006)
#
#  https://github.com/harisekhon/bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/harisekhon
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

srcdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ "$(uname)" = Darwin ]; then
    export APPLE=1
    export OSX=1
fi

# enable color support for ls
if [ "$TERM" != "dumb" ] && \
   [ -z "${APPLE:-}" ]; then
    eval "$(dircolors -b)"
fi

[ -f /etc/profile     ] && . /etc/profile
[ -f /etc/bash/bashrc ] && . /etc/bash/bashrc
[ -f /etc/bashrc      ] && . /etc/bashrc

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

# Stops duplicate commands next to each other from being logged
# This totally screws up my terminal to the point where I can't even ssh, I get a strange network tcp network destination unreachable error
#export HISTCONTROL=ignoredups
HISTCONTROL=ignoredups:ignorespace

# Neat trick "[ \t]*" to exclude any command by just prefixing it with a space. Fast way of going stealth for pw entering on cli
# & here means any duplicate patterns, others are simple things like built-ins and ls and stuff you don't need history for
#export HISTIGNORE="[ \t]*:&:ls:[bf]g:exit"

# Make sure we append rather than overwrite history
shopt -s histappend

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

[ -n "${APPLE:-}" ] || setterm -blank 0

# Prevent core dumps which can leak sensitive information
ulimit -c 0

# Let's be stingey with permissions
# This causes problems where root installs libraries and my user account can't access them
if [ $EUID = 0 ]; then
    umask 0022
else
    # This causes no end of problems when doing sudo command which retains 0077 and breaks library access. If can get sudo to implicitly read .bashrc to reset this (and prompt colour would be nice) then re-enable this tighter 0077 umask
    #umask 0077
    umask 0022
fi

# make less more friendly for non-text input files, see lesspipe(1)
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

# ============================================================================ #

sudo=sudo
if [ $EUID -eq 0 ]; then
    sudo=""
fi

#export PATH="${PATH%%:$HOME/github*}"
add_PATH(){
    local path
    path="${1:-}"
    path="${path%/}"
    if ! [[ "$PATH" =~ (^|:)$path(:|$) ]]; then
        export PATH="$PATH:$path"
    fi
}

add_PATH "/sbin"
add_PATH "/usr/sbin"
add_PATH "/usr/local/sbin"
add_PATH "$HOME/bin"
add_PATH "$srcdir"

# ============================================================================ #

for src in "$srcdir/.bash.d/"*.sh; do
    # shellcheck disable=SC1090
    . "$src"
done
