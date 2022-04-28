#!/usr/bin/env bash
# shellcheck disable=SC2230
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: circa 2010 - 2012 (forked from .bashrc)
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
#                                  R a n c i d
# ============================================================================ #

export RANCID_HOME=~/rancid

#flogin(){
#    title "$1"
#    command flogin "${@:1}"
#    title " "
#}

# l33ter way of generating functions for all of the rancid programs
#for x in $(ls "$RANCID_HOME/bin/"*login | sed 's/.*\///;s/*$//'); do
#    eval "$x"'(){ title "$1"
#    command '"$x"' ${@:1}
#    title " "
#    }'
#done

# More prim and proper abstracted function with minimal function code
rancidlogin_func(){
    local prog="$1"
    local host="$2"
    shift
    title "$host"
    command "$prog" "$@"
    title "$LAST_TITLE"
}

#for x in "$RANCID_HOME/bin/"*login; do y=${x##*/}; alias "$y"="rancidlogin_func $y"; done
for x in "$RANCID_HOME/bin/"*login; do
    y="${x##*/}"
    # needs to be evaluated here to build dynamic aliases
    # shellcheck disable=SC2139,SC2140
    alias "$y"="rancidlogin_func $y"
done

# for x in "$RANCID_HOME/bin/"*login; do y="${x##*/}"; which "${y%ogin}" &>/dev/null || alias "${y%ogin}"="$y"; done
# This is slow to do every time so just past the echo output from:
# for x in "$RANCID_HOME/bin/"*login; do y="${x##*/}"; which "${y%ogin}" &>/dev/null || echo alias "${y%ogin}"="$y"; done
#alias al=alogin
#alias avol=avologin
#alias bl=blogin
#alias cl=clogin
#alias el=elogin
#alias fl=flogin
#alias hl=hlogin
#alias htl=htlogin
#alias jl=jlogin
#alias mrvl=mrvlogin
# nl is a real program so skipped nlogin
#alias nsl=nslogin
#alias rivl=rivlogin
#alias tl=tlogin
#alias tntl=tntlogin
