#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2015-05-25 01:38:24 +0100 (Mon, 25 May 2015)
#
#  https://github.com/harisekhon/bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help improve or steer this or other code I publish
#
#  http://www.linkedin.com/in/harisekhon
#

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

. "$srcdir/lib/utils.sh"

if [ -z "$(find "${1:-.}" -maxdepth 2 -type f -iname '*.py' -o -iname '*.jy')" ]; then
    return 0 &>/dev/null || :
    exit 0
fi

section "P y L i n t"

start_time="$(start_timer)"

if [ -n "${NOPYLINT:-}" ]; then
    echo '$NOPYLINT environment variable set, skipping PyLint error checks'
elif [ -n "${QUICK:-}" ]; then
    echo '$QUICK environment variable set, skipping PyLint error checks'
else
    if which pylint &>/dev/null; then
        # Can't do this in one pass because pylint -E raises wrong-import-position when it doesn't individually and refuses to respect --disable
        #prog_list="
        for x in $(find "${1:-.}" -maxdepth 2 -type f -iname '*.py' -o -iname '*.jy' | sort); do
            #echo "checking if $x is excluded"
            isExcluded "$x" && continue
            #echo "added $x for testing"
            #prog_list="$prog_list $x"
            echo "pylint -E $x"
            pylint -E "$x"
        done
        #echo
        #echo "Checking for coding errors:"
        #echo
        #echo "pylint -E $prog_list"
        #echo
        #pylint -E $prog_list
        hr; echo
    fi
fi

time_taken "$start_time"
section2 "PyLint checks passed"
echo
