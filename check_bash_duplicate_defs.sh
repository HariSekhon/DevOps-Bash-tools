#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2019-08-02 13:30:09 +0100 (Fri, 02 Aug 2019)
#
#  https://github.com/harisekhon/bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/harisekhon
#

# Checks for duplicate function or alias definitions within a given collection of bash scripts - useful for checking across many .bash.d/ includes
#
# This isn't caught by shellcheck - for example it's common to alias 'p' to ping, but I also do this for 'kubectl get pods'

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x

check_duplicate_defs(){
    check_duplicate_functions "$@"
    check_duplicate_aliases "$@"
}

check_duplicate_functions(){
    local function_dups
    function_dups="$(
        grep -Eho '^[[:space:]]*(function[[:space:]]+)?[[:alnum:]-]+[[:space:]]*\(' "$@" |
        sed 's/^[[:space:]]*\(function[[:space:]]*\)*//; s/[[:space:]]*(.*//' |
        sort |
        uniq -d
    )"
    if [ -n "$function_dups" ]; then
        echo "Duplicate functions detected across input files:  $*"
        echo
        echo "$function_dups"
        echo
        exit 1
    fi
}

check_duplicate_aliases(){
    local alias_dups
    alias_dups="$(
        grep -Eho '^[[:space:]]*alias[[:space:]]+[[:alnum:]]+=' "$@" |
        sed 's/^[[:space:]]*alias[[:space:]]*//; s/=$//' |
        sort |
        uniq -d
    )"
    if [ -n "$alias_dups" ]; then
        echo "Duplicate aliases detected across input files:  $*"
        echo
        echo "$alias_dups"
        echo
        exit 1
    fi
}

check_duplicate_defs "$@"
