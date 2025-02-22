#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2019-10-01 17:18:03 +0100 (Tue, 01 Oct 2019)
#
#  https://github.com/HariSekhon/DevOps-Bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help improve or steer this or other code I publish
#
#  https://www.linkedin.com/in/HariSekhon
#

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=lib/utils.sh
. "$srcdir/lib/utils.sh"

filelist="$(find "${1:-.}" -type f -name '*.json' | sort)"

if [ -z "$filelist" ]; then
    # shellcheck disable=SC2317
    return 0 &>/dev/null ||
    exit 0
fi

section "JSON Syntax Checks"

start_time="$(start_timer)"

if [ -n "${NOSYNTAXCHECK:-}" ]; then
    echo "\$NOSYNTAXCHECK environment variable set, skipping JSON syntax checks"
    echo
elif [ -n "${QUICK:-}" ]; then
    echo "\$QUICK environment variable set, skipping JSON syntax checks"
    echo
else
    if ! command -v jsonlint &>/dev/null; then
        echo "jsonlint not found in \$PATH, not running JSON syntax checks"
        # shellcheck disable=SC2317
        return 0 &>/dev/null ||
        exit 0
    fi
    type -P jsonlint
    printf "version: "
    jsonlint --version || :
    echo
    max_len=0
    for x in $filelist; do
        if [ "${#x}" -gt "$max_len" ]; then
            max_len="${#x}"
        fi
    done
    # to account for the semi colon
    ((max_len + 1))
    for x in $filelist; do
        isExcluded "$x" && continue
        [[ "$x" =~ multirecord ]] && continue
        printf "%-${max_len}s " "$x:"
        set +eo pipefail
        output="$(jsonlint "$x")"
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
                # shellcheck disable=SC2317
                return 1 &>/dev/null ||
                exit 1
            fi
        fi
        set -eo pipefail
    done
    time_taken "$start_time"
    section2 "All JSON files passed syntax check"
fi
echo
