#!/usr/bin/env bash
# shellcheck disable=SC2230
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: circa 2006 (forked from .bashrc and later functions.sh)
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
#                                     V I M
# ============================================================================ #

bash_tools="${bash_tools:-$(dirname "${BASH_SOURCE[0]}")/..}"

# shellcheck disable=SC1090,SC1091
. "$bash_tools/.bash.d/os_detection.sh"

# vim() function is in title.sh as it is tightly integrated with the functions in there and not necessary otherwise

vimhome(){
    # must expand in vim, not in shell
    # shellcheck disable=SC2016
    vim -Nesc '!echo $VIMRUNTIME' -c qa |
    #tr -dc '[:alnum:]/\r\n'
    sed 's,[^/]*/,/,'
}

cdvimhome(){
    # shellcheck disable=SC2164
    cd "$(vimhome)"
}

vimfiletypes(){
    cdvimhome || return 1
    find syntax ftplugin -iname '*.vim' -exec basename -s .vim {} + | sort -u
}

gitgrepvim(){
    if [ $# -lt 2 ]; then
        echo "usage: gitgrepvim <pattern>"
        return 3
    fi
    # want splitting
    # shellcheck disable=SC2046
    vim $(git grep -i "$*" | sed 's/:.*//' | sort -u)
}
alias ggrepv=gitgrepvim

grepvim(){
    if [ $# -lt 2 ]; then
        echo "usage: grepvim <pattern> <files>"
        return 3
    fi
    # want splitting
    # shellcheck disable=SC2046
    vim $(grep -l "$1" "$@" | sort -u)
}
alias grepv=grepvim
alias vimgrep=grepvim

vimchanged(){
    local git_root
    git_root="$(git_root)"
    # want splitting
    # shellcheck disable=SC2046
    vim "$@" $(git status --porcelain | awk '/^.M/ {$1=""; print}' | sed "s|^[[:space:]]|$git_root/|")
}

filesvim(){
    local files=()
    # mapfile not available on Mac and read -a only takes first result
    # shellcheck disable=SC2207
    IFS=$'\n' files=($(find . -iname "$@" | sort -u))
    if [ -n "${files[*]}" ]; then
        vim "${files[@]}"
    fi
}
alias fvim=filesvim
alias vimf=fvim

# vim which
vw(){
    local path
    if [ -z "$1" ]; then
        echo "usage: vw <filename>"
        return 1
    fi
    path="$(which "$1")"
    if [ -z "$path" ]; then
        echo "File not found in \$PATH: $1"
        return 1
    fi
    "$EDITOR" "$path"
}

vihosts(){
    [ $EUID -eq 0 ] && sudo="" || sudo=sudo
    $sudo vim /etc/hosts
    $sudo pkill -1 dnsmasq
}

vimup(){
    local arg="$1"
    up_target="$(findup "$arg")"
    [ -n "$up_target" ] || return 1
    vim "$(findup "$1")"
}
