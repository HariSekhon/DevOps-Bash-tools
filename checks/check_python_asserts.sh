#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2018-10-03 12:50:57 +0100 (Wed, 03 Oct 2018)
#
#  https://github.com/HariSekhon/DevOps-Bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help improve or steer this or other code I publish
#
#  https://www.linkedin.com/in/HariSekhon
#

set -eu
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=lib/utils.sh
. "$srcdir/lib/utils.sh"

# shellcheck source=lib/utils.sh
. "$srcdir/lib/python.sh"

# maxdepth 2 to avoid recursing submodules which have their own checks
files="$(find_python_jython_files . -maxdepth 2)"

if [ -z "$files" ]; then
    # shellcheck disable=SC2317
    return 0 &>/dev/null ||
    exit 0
fi

section "Python - find and alert on any usage of assert outside of /test/"

start_time="$(start_timer)"

found=0
while read -r filename; do
    type isExcluded &>/dev/null && isExcluded "$filename" && echo -n '-' && continue
    # exclude pytests
    [[ "$filename" = ./test/* ]] && continue
    echo -n '.'
    if grep -E '^[[:space:]]+\bassert\b' "$filename"; then
        echo
        echo "WARNING: $filename contains 'assert'!! This could be disabled at runtime by PYTHONOPTIMIZE=1 / -O / -OO and should not be used!! "
        found=1
        #if ! is_CI; then
        #    exit 1
        #fi
    fi
done <<< "$files"

time_taken "$start_time"

if [ -n "${WARN_ONLY:-}" ]; then
    section2 "Python OK - assertions scan finished"
else
    if [ $found != 0 ]; then
        exit 1
    fi
    section2 "Python OK - no assertions found in normal code"
fi

echo
