#!/usr/bin/env bash
# shellcheck disable=SC2230
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2022-01-06 18:34:01 +0000 (Thu, 06 Jan 2022)
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

# shellcheck disable=SC1090
. "$srcdir/lib/utils.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Recurses a given directory tree or \$PWD, finding all Groovy files and validating them using 'groovyc'

Useful for doing basic linting on simple self-contained Groovy scripts such as Jenkins Shared Libraries
"

help_usage "$@"

directory="${1:-.}"
shift ||:

echo "Checking for Groovy files"
filelist="$(find "$directory" -type f -iname '*.groovy' | sort)"
if [ -z "$filelist" ]; then
    return 0 &>/dev/null || :
    exit 0
fi

section "G r o o v y"

if ! type -P groovyc &>/dev/null; then
    echo "WARNING: groovyc not found in \$PATH, skipping Groovy checks"
    echo
    exit 0
fi

start_time="$(start_timer)"

groovy --version
echo

check_groovyc(){
    local filename="$1"
    shift || :
    # this requires far too many function exports for all called CI functions
    #isExcluded "$filename" && return 0
    echo "groovyc $filename $*" >&2
    if ! groovyc "$filename" "$@" >&2; then
        echo 1
        exit 1
    fi
}

echo "building file list" >&2
tests="$(
    while read -r filename; do
        echo "check_groovyc \"$filename\""
    done <<< "$filelist"
)"

cpu_count="$(cpu_count)"
multiplier=1  # doesn't get faster increasing this in tests, perhaps even slightly slower due to context switching
parallelism="$((cpu_count * multiplier))"

echo "found $cpu_count cores, running $parallelism parallel jobs"
echo

# export functions to use in parallel
export -f check_groovyc
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
    section2 "Groovy checks passed"
else
    echo "ERROR: $count broken groovy files detected!" >&2
    echo >&2
    section2 "Groovy checks FAILED"
    exit 1
fi
