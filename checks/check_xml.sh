#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2022-06-13 16:18:51 +0100 (Mon, 13 Jun 2022)
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

#if [ $# -gt 0 ]; then
#    filelist="$*"
#else
    # can point to test.json as an explicit argument
    # could check *.json too but in DevOps Python Tools repo multirecord.json would break as this cannot handle multi-json record files
    #filelist="$(find "${1:-.}" -type f -name '*.y*ml' -o -type f -name '*.json' | sort)"
    filelist="$(find "${1:-.}" -type f -name '*.xml' | sort)"
#fi

if [ -z "$filelist" ]; then
    return 0 &>/dev/null ||
    exit 0
fi

section "XML Syntax Checks"

if [ -n "${NOSYNTAXCHECK:-}" ]; then
    echo "\$NOSYNTAXCHECK environment variable set, skipping XML syntax checks"
    echo
    exit 0
elif [ -n "${QUICK:-}" ]; then
    echo "\$QUICK environment variable set, skipping XML syntax checks"
    echo
    exit 0
fi


if ! command -v xmllint &>/dev/null; then
    echo "xmllint not found in \$PATH, not running XML syntax checks"
    exit 0
fi

start_time="$(start_timer)"

type -P xmllint
xmllint --version
echo

export max_len=0
for x in $filelist; do
    if [ "${#x}" -gt "$max_len" ]; then
        max_len="${#x}"
    fi
done
# to account for the colon
((max_len + 1))

check_xml(){
    local filename="$1"
    printf "%-${max_len}s " "$filename:" >&2
    set +eo pipefail
    output="$(xmllint "$filename")"
    result=$?
    set -eo pipefail
    # shellcheck disable=SC2181
    if [ "$result" -eq 0 ]; then
        echo "OK" >&2
    else
        echo "FAILED" >&2
        if [ -z "${QUIET:-}" ]; then
            echo >&2
            sed "s|^|$filename: |" <<< "$output" >&2
            echo >&2
        fi
        echo 1
        exit 1
    fi
}

echo "building file list" >&2
tests="$(
    for filename in $filelist; do
        #isExcluded "$filename" && continue
        echo "check_xml $filename"
    done
)"

cpu_count="$(cpu_count)"
multiplier=1  # doesn't get faster increasing this in tests, perhaps even slightly slower due to context switching
parallelism="$((cpu_count * multiplier))"

echo "found $cpu_count cores, running $parallelism parallel jobs"
echo

# export functions to use in parallel
export -f check_xml
export SHELL=/bin/bash  # Debian docker container doesn't set this and defaults to sh, failing to find exported function

set +eo pipefail
tally="$(parallel -j "$parallelism" <<< "$tests")"
exit_code=$?
set -eo pipefail

count="$(awk '{sum+=$1} END{print sum}' <<< "$tally")"

echo >&2
time_taken "$start_time"
echo >&2

if [ $exit_code -eq 0 ]; then
    section2 "All XML files passed syntax check"
else
    echo "ERROR: $count broken xml files detected!" >&2
    echo >&2
    section2 "XML checks failed"
    exit 1
fi
