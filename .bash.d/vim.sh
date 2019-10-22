#!/usr/bin/env bash
# shellcheck disable=SC2230
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: circa 2006 (forked from .bashrc and later functions.sh)
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
#                                     V I M
# ============================================================================ #

bash_tools="${bash_tools:-$(dirname "${BASH_SOURCE[0]}")/..}"

# shellcheck disable=SC1090
. "$bash_tools/.bash.d/os_detection.sh"

# vim() functions is in title.sh as it is tightly integrated with the functions in there and not necessary otherwise

vimhome(){
    # must expand in vim, not in shell
    # shellcheck disable=SC2016
    vim -Nesc '!echo $VIMRUNTIME' -c qa |
    #tr -dc '[:alnum:]/\r\n'
    sed 's,[^/]*/,/,'
}

vimfiletypes(){
    cd "$(vimhome)" || return 1
    find syntax ftplugin -iname '*.vim' -exec basename -s .vim {} + | sort -u
}

grepvim(){
    # shellcheck disable=SC2046
    vim $(git grep -i "$*" | sed 's/:.*//')
}
alias grepv=grepvim

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
