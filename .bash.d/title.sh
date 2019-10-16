#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: circa 2006 - 2012 (forked from .bashrc)
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
#                             T i t l e   M a g i c
# ============================================================================ #

# Sets the Screen and Terminal titles

alias ti="title"
# static title - turn dynamic prompt escape codes off, while optionally setting new title
alias sti="dpoff >/dev/null; ti"

#title(){ echo -ne '\033]0;'"$@"'\007'; }

#termtitle(){
#    local termtitle="${*:- }"
#       #[ -z "${termtitle## }" ]
#    #if isscreen &&
#    #   [ -z "$termtitle" ]; then
#    #    termtitle="screen $WINDOW"
#    #fi
#    printf '\033]0;%s\007' "$termtitle"
#}

termtitle(){
    printf '\033]0;%s\007' "${*:- }"
}

isscreen(){
    # $STY is only set in screen it seems so this determines if we're in screen
    [ -n "$STY" ]
}

screentitle(){
    if isscreen; then
        printf "\033k%s\033\\" "${*:- }"
        # or
        # screen -X title "$*"
    fi
}

title(){
    export LAST_TITLE="$TITLE"
    #if [ $# -eq 0 ]; then
    #    return
    # various commands will reset the title after their commands so skip those calls if NO_SCREEN_UPDATES is set
    if [ -z "$*" ] &&
         [ "$NO_SCREEN_UPDATES" = "1" ]; then
        return
    fi
    export TITLE="$*"
    termtitle "$TITLE"
    screentitle "$TITLE"
}

# .bashrc reload causes title loss if enabling this
#title
# so instead just reset the termtitle which we don't see anyway and get rid of that annoying Unnamed in the title bar
termtitle " "

# ============================================================================ #

# toggle dynamic prompt on / off
dpstatus(){
    if grep -q '^\\\[\\ek\\e\\\\\\]' <<< "$PS1"; then
        echo "enabled"
        return 0
    else
        echo "disabled"
        return 1
    fi
}

# dynamic prompt escape codes off
dpoff(){
    if dpstatus >/dev/null; then
        title " "
        PS1="${PS1#\\[\\ek\\e\\\\\\\]}"
        export PS1
        export NO_SCREEN_UPDATES=1
        echo "disabled"
    fi
}

# dynamic prompt escape codes on
dpon(){
    if ! dpstatus >/dev/null; then
        PS1="${SCREEN_ESCAPE}${PS1}"
        export PS1
        export NO_SCREEN_UPDATES=0
        echo "enabled"
    fi
}

# toggle dynamic prompt on/off
dp(){
    if dpstatus; then
        printf '\b\renabled => '
        dpoff
    else
        printf '\b\rdisabled => '
        dpon
    fi
    title
}

# ============================================================================ #

man(){
    title "man $1"
    command man "$@"
    title "$LAST_TITLE"
}

sudo(){
    title "sudo $1"
    command sudo "$@"
    title "$LAST_TITLE"
}

vim(){
    local title=""
    #until [ -z "$1" ]; do
    for x in "$@"; do
        case "$x" in
            -*) :
                ;;
            +*) :
                ;;
             *) title="$title$x "
                ;;
        esac
        #shift
    done
    local num=10
    [ -f ~/shorttitle ] && num=3
    title="${title//.txt/}"
    #if dpstatus >/dev/null; then
        if echo "$title" | grep -q docs/; then
            title="$(basename "$title")"
            title "d${title:0:$num}"
        else
            title="$(basename "$title")"
            title "${title:0:$num}"
        fi
    #fi
    command vim "$@"
    if dpstatus >/dev/null; then title; fi
}

