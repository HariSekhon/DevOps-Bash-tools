#!/usr/bin/env bash
# shellcheck disable=SC2230
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2016-01-22 20:54:53 +0000 (Fri, 22 Jan 2016)
#
#  https://github.com/HariSekhon/DevOps-Bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback
#
#  https://www.linkedin.com/in/HariSekhon
#

# This really only checks basic syntax, if you're made command errors this won't catch it

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=lib/utils.sh
. "$srcdir/lib/utils.sh"

if [ $# -eq 0 ]; then
    if [ -z "$(find "${1:-.}" -type f -iname '*.sh')" ]; then
        # shellcheck disable=SC2317
        return 0 &>/dev/null ||
        exit 0
    fi
fi

section "Shell Syntax Checks"

start_time="$(start_timer)"

if ! type -P shellcheck &>/dev/null; then
    echo "WARNING: shellcheck not installed, will only do basic checks"
    echo
fi

bash --version
echo

check_shell_syntax(){
    echo -n "checking shell syntax: $1 "
    if grep -q '#!/bin/bas[h]' "$1"; then
        # quotes in middle disrupt warning on our own script
        echo "WARNING: '#!""/bin/bash' detected, consider using '#!/usr/bin/env bash' instead"
    fi
    bash -n "$1"
    if type -P shellcheck &>/dev/null; then
        local basename="${1##*/}"
        local dirname
        dirname="$(dirname "$1")"
        # this allows following source hints relative to the source file to be safe to run from any $PWD
        if ! pushd "$dirname" &>/dev/null; then
            echo "ERROR: failed to pushd to $dirname"
            exit 1
        fi
        # -x allows to follow source hints for files not given as arguments
        shellcheck -x "$basename" || :
        if ! popd &>/dev/null; then
            echo "ERROR: failed to popd from $dirname"
        fi
    fi
    echo "=> OK"
}

recurse_dir(){
    for x in $(find "${1:-.}" -type f -iname '*.sh' | sort); do
        isExcluded "$x" && continue
        [[ "$x" =~ ${EXCLUDED:-} ]] && continue
        check_shell_syntax "$x"
    done
}

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
