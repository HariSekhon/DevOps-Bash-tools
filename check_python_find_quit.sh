#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2016-02-16 17:08:18 +0000 (Tue, 16 Feb 2016)
#
#  https://github.com/harisekhon/bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help improve or steer this or other code I publish
#
#  https://www.linkedin.com/in/harisekhon
#

set -eu
[ -n "${DEBUG:-}" ] && set -x
srcdir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

. "$srcdir/lib/utils.sh"

if [ -z "$(find "${1:-.}" -maxdepth 2 -type f -iname '*.py' -o -iname '*.jy')" ]; then
    return 0 &>/dev/null || :
    exit 0
fi

section "Python - finding any instances of calling quit() in code which are probably typos for custom qquit()"

start_time="$(start_timer)"

for x in $(find "${1:-.}" -maxdepth 2 -type f -iname '*.py' -o -iname '*.jy' | sort); do
    type isExcluded &>/dev/null && isExcluded "$x" && echo -n '-' && continue
    echo -n '.'
    if grep -Eq '^[^#]*\bquit\b' "$x"; then
        echo
        grep -Eq '^[^#]*\bquit\b' "$x"
        echo
        echo
        echo "ERROR: $x contains quit() call!! Typo?"
        exit 1
    fi
done

time_taken "$start_time"
section2 "Python OK - no quit() calls found"
echo
