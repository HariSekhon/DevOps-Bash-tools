#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2019-08-02 13:30:09 +0100 (Fri, 02 Aug 2019)
#
#  https://github.com/HariSekhon/DevOps-Bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/HariSekhon
#

# Checks for duplicate function or alias definitions within a given collection of bash scripts - useful for checking across many .bash.d/ includes
#
# This isn't caught by shellcheck - for example it's common to alias 'p' to ping, but I also do this for 'kubectl get pods'

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=lib/utils.sh
. "$srcdir/lib/utils.sh"

section "Checking for Bash duplicate definitions (functions, aliases)"

start_time="$(start_timer)"

check_duplicate_defs(){
    echo "Checking for duplicate definitions in the following files:"
    echo
    for x in "$@"; do
        echo "$x"
    done
    echo
    check_duplicate_functions "$@"
    check_duplicate_aliases "$@"
    check_duplicate_aliases_vs_functions "$@"
}

get_functions(){
    # ignore definitions that happen inside indented blocks such as if/else statements creating conditional functions
    #grep -Eh '^[[:space:]]*(function[[:space:]]+)?[[:alnum:]-]+[[:space:]]*\(' "$@" 2>/dev/null |
    grep -Eh '^(function[[:space:]]+)?[[:alnum:]-]+[[:space:]]*\(' "$@" 2>/dev/null |
    grep -Ev '^[[:space:]]*for[[:space:]]*\(\(' |
    sed 's/^[[:space:]]*\(function[[:space:]]*\)*//; s/[[:space:]]*(.*//' |
    sort
}

get_aliases(){
    grep -Eho '^[[:space:]]*alias[[:space:]]+[[:alnum:]]+=' "$@" 2>/dev/null |
    sed 's/^[[:space:]]*alias[[:space:]]*//; s/=$//' |
    sort
}

check_duplicate_functions(){
    echo "* Checking for duplicate function definitions"
    echo
    local function_dups
    set +o pipefail
    function_dups="$(get_functions "$@" | uniq -d)"
    if [ -n "$function_dups" ]; then
        echo "Duplicate functions detected across input files!"
        echo
        for x in $function_dups; do
            grep -Eno "^[[:space:]]*(function[[:space:]]+)?${x}[[:space:]]*\\(" "$@" 2>/dev/null || :
        done
        echo
        exit 1
    fi
}

check_duplicate_aliases(){
    echo "* Checking for duplicate alias definitions"
    echo
    local alias_dups
    set +o pipefail
    alias_dups="$(get_aliases "$@" | uniq -d)"
    if [ -n "$alias_dups" ]; then
        echo "Duplicate aliases detected across input files!"
        echo
        for x in $alias_dups; do
            grep -En "^[[:space:]]*alias[[:space:]]+${x}=" "$@" 2>/dev/null || :
        done
        echo
        echo
        exit 1
    fi
}

check_duplicate_aliases_vs_functions(){
    echo "* Checking for duplicate alias vs function definitions"
    echo
    local defs
    local duplicate_defs
    defs="$(get_functions "$@")
$(get_aliases "$@")"
    duplicate_defs="$(sort <<< "$defs" | uniq -d)"
    if [ -n "$duplicate_defs" ]; then
        echo "Duplicate function vs alias definitions detected across input files!"
        echo
        for x in $duplicate_defs; do
            grep -Eno -e "^[[:space:]]*alias[[:space:]]+${x}=" \
                -e "^[[:space:]]*(function[[:space:]]+)?${x}[[:space:]]*\\(" \
                      "$@" 2>/dev/null || :
        done
        echo
        echo
        exit 1
    fi
}

if [ $# -gt 0 ]; then
    check_duplicate_defs "$@"
else
    # only this repo
    #check_duplicate_defs "$srcdir/.bashrc" "$srcdir"/.bash.d/*.sh
    # $HOME + this repo
    check_duplicate_defs ~/.bashrc ~/.bash.d/*.sh "$srcdir/../.bashrc" "$srcdir"/.bash.d/*.sh
fi

time_taken "$start_time"
section2 "No duplicate bash definitions found"
echo
