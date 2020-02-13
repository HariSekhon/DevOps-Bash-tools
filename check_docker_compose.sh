#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-01-06 13:43:32 +0000 (Mon, 06 Jan 2020)
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

# shellcheck source=lib/utils.sh
. "$srcdir/lib/utils.sh"

filelist="$(find "${1:-.}" -type f -name '*docker-compose*.y*ml' | sort)"

if [ -z "$filelist" ]; then
    return 0 &>/dev/null ||
    exit 0
fi

section "Docker Compose Syntax Checks"

start_time="$(start_timer)"

if [ -n "${NOSYNTAXCHECK:-}" ]; then
    echo "\$NOSYNTAXCHECK environment variable set, skipping docker-compose syntax checks"
    echo
elif [ -n "${QUICK:-}" ]; then
    echo "\$QUICK environment variable set, skipping docker-compose syntax checks"
    echo
else
    if ! command -v docker-compose &>/dev/null; then
        echo "docker-compose not found in \$PATH, not running syntax checks"
        return 0 &>/dev/null || exit 0
    fi
    max_len=0
    for x in $filelist; do
        if [ ${#x} -gt $max_len ]; then
            max_len=${#x}
        fi
    done
    # to account for the semi colon
    ((max_len + 1))
    for x in $filelist; do
        isExcluded "$x" && continue
        printf "%-${max_len}s " "$x:"
        set +eo pipefail
        output="$(docker-compose -f "$x" config >/dev/null)"
        # shellcheck disable=SC2181
        if [ $? -eq 0 ]; then
            echo "OK"
        else
            echo "FAILED"
            if [ -z "${QUIET:-}" ]; then
                echo
                echo "$output"
                echo
            fi
            if [ -z "${NOEXIT:-}" ]; then
                return 1 &>/dev/null || exit 1
            fi
        fi
        set -eo pipefail
    done
    time_taken "$start_time"
    section2 "All docker-compose files passed syntax check"
fi
echo
