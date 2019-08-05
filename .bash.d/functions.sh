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
#                             Bash General Functions
# ============================================================================ #

pass(){
    read -s -p 'password: ' PASSWORD
    echo
    export PASSWORD
}

hr(){
    echo "# ============================================================================ #"
}

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

