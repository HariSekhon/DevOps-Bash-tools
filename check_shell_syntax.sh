#!/usr/bin/env bash
# shellcheck disable=SC2230
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2016-01-22 20:54:53 +0000 (Fri, 22 Jan 2016)
#
#  https://github.com/harisekhon/bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback
#
#  https://www.linkedin.com/in/harisekhon
#

# This really only checks basic syntax, if you're made command errors this won't catch it

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# shellcheck disable=SC1090
. "$srcdir/lib/utils.sh"

if [ $# -eq 0 ]; then
    if [ -z "$(find "${1:-.}" -type f -iname '*.sh')" ]; then
        return 0 &>/dev/null || :
        exit 0
    fi
fi

section "Shell Syntax Checks"

check_shell_syntax(){
    echo -n "checking shell syntax: $1 "
    if grep -q '#!/bin/bas[h]' "$1"; then
        # quotes in middle disrupt warning on our own script
        echo "WARNING: '#!""/bin/bash' detected, consider using '#!/usr/bin/env bash' instead"
    fi
    bash -n "$1"
    if which shellcheck &>/dev/null; then
        shellcheck "$1" || :
    fi
    echo "=> OK"
}

recurse_dir(){
    for x in $(find "${1:-.}" -type f -iname '*.sh' | sort); do
        isExcluded "$x" && continue
        check_shell_syntax "$x"
    done
}

start_time="$(start_timer)"

if ! which shellcheck &>/dev/null; then
    echo "WARNING: shellcheck not installed, will only do basic checks"
    echo
fi

if [ $# -gt 0 ]; then
    for x in "$@"; do
        if [ -d "$x" ]; then
            recurse_dir "$x"
        else
            check_shell_syntax "$x"
        fi
    done
else
    recurse_dir .
fi

time_taken "$start_time"
section2 "All Shell programs passed syntax check"
echo
