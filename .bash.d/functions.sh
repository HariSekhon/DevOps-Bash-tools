#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: circa 2006 (forked from .bashrc)
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
#                  B a s h   G e n e r a l   F u n c t i o n s
# ============================================================================ #

pg(){
    # don't want pgrep, want color coding
    # shellcheck disable=SC2009
    ps -ef |
    grep -i --color=yes "$@" |
    grep -v grep
}

checkprog(){
    if command -v "$1" &>/dev/null; then
        return 0
    else
        echo "$1 could not be found in path"
        return 1
    fi
}

pass(){
    read -r -s -p 'password: ' PASSWORD
    echo
    export PASSWORD
}

hr(){
    echo "# ============================================================================ #"
}

currentScreenResolution(){
    #xrandr | awk '/\*/ {print $1}'
    xdpyinfo  | awk '/dimensions/ {print $2}'
}

yy(){
    cal `date '+%Y'`
}

# ============================================================================ #

strLastIndexOf(){
    local str="$1"
    local substr="$2"
    local remainder="${str##*$substr}"
    local lastIndex=$((${#str} - ${#remainder}))
    echo $lastIndex
}

# this idea's is a bust so far...
#function c(){
#    screen -t "$@" bash -c ". ~/.bashrc && eval $@"
#}

progs(){
    find "${@:-.}" -type f |
    grep -Evf ~/code_regex_exclude.txt |
    grep -v -e '/lib/' -e '.*-env.sh' -e '/tests/'
}

progs2(){
    find "${@:-.}" -type f -o -type l |
    grep -Evf ~/code_regex_exclude.txt
}

findpy(){
    find "${@:-.}" -type f -iname '*.py' -o -iname '*.jy' |
    grep -vf ~/code_regex_exclude.txt
}
