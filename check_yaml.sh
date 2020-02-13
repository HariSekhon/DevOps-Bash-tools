#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2019-10-01 17:24:58 +0100 (Tue, 01 Oct 2019)
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

# use .yamllint in $PWD or default to $srcdir/yamllint/config
export XDG_CONFIG_HOME="$srcdir"

# shellcheck source=lib/utils.sh
. "$srcdir/lib/utils.sh"

#if [ $# -gt 0 ]; then
#    filelist="$*"
#else
    # can point to test.json as an explicit argument
    # could check *.json too but in DevOps Python Tools repo multirecord.json would break as this cannot handle multi-json record files
    #filelist="$(find "${1:-.}" -type f -name '*.y*ml' -o -type f -name '*.json' | sort)"
    filelist="$(find "${1:-.}" -type f -name '*.y*ml' | sort)"
#fi

if [ -z "$filelist" ]; then
    return 0 &>/dev/null ||
    exit 0
fi

section "YAML Syntax Checks"

start_time="$(start_timer)"

if [ -n "${NOSYNTAXCHECK:-}" ]; then
    echo "\$NOSYNTAXCHECK environment variable set, skipping YAML syntax checks"
    echo
elif [ -n "${QUICK:-}" ]; then
    echo "\$QUICK environment variable set, skipping YAML syntax checks"
    echo
else
    if ! command -v yamllint &>/dev/null; then
        echo "yamllint not found in \$PATH, not running YAML syntax checks"
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
        output="$(yamllint "$x")"
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
    section2 "All YAML files passed syntax check"
fi
echo
