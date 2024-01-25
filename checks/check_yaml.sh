#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2019-10-01 17:24:58 +0100 (Tue, 01 Oct 2019)
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

# use .yamllint in $PWD or default to $srcdir/yamllint/config
#export XDG_CONFIG_HOME="$srcdir"

#export YAMLLINT_CONFIG_FILE="$srcdir/.config/yamllint/config"
export YAMLLINT_CONFIG_FILE="${YAMLLINT_CONFIG_FILE:-$srcdir/../configs/.yamllint.yaml}"

# shellcheck disable=SC2034,SC2154
usage_description="
Checks a yaml file or recurses a directory of yamls
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="file1 [file2 file3 ...]"

help_usage "$@"

#min_args 1 "$@"

filelist=()

for arg in "${@:-.}"; do
    if [ -d "$arg" ]; then
        filelist+=( "$(find "$arg" -type f -name '*.y*ml' | sort)" )
    else
        filelist+=("$arg")
    fi
done

if [ -z "${filelist[*]}" ]; then
    # shellcheck disable=SC2317
    return 0 &>/dev/null ||
    exit 0
fi

section "YAML Syntax Checks"

if [ -n "${NOSYNTAXCHECK:-}" ]; then
    echo "\$NOSYNTAXCHECK environment variable set, skipping YAML syntax checks"
    echo
    exit 0
elif [ -n "${QUICK:-}" ]; then
    echo "\$QUICK environment variable set, skipping YAML syntax checks"
    echo
    exit 0
fi


if ! command -v yamllint &>/dev/null; then
    echo "yamllint not found in \$PATH, not running YAML syntax checks"
    exit 0
fi

start_time="$(start_timer)"

type -P yamllint
yamllint --version
echo

export max_len=0
for x in $filelist; do
    if [ "${#x}" -gt "$max_len" ]; then
        max_len="${#x}"
    fi
done
# to account for the colon
((max_len + 1))

check_yaml(){
    local filename="$1"
    printf "%-${max_len}s " "$filename:" >&2
    set +eo pipefail
    # doesn't pick up the config without an explicit -c ...
    output="$(yamllint -c "$YAMLLINT_CONFIG_FILE" "$filename")"
    result=$?
    set -eo pipefail
    # shellcheck disable=SC2181
    if [ $result -eq 0 ]; then
        echo "OK" >&2
    else
        echo "FAILED" >&2
        if [ -z "${QUIET:-}" ]; then
            echo >&2
            # shellcheck disable=SC2001
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
        # very expensive git log and regex matches against every file
        #isExcluded "$filename" && continue
        echo "check_yaml $filename"
    done
)"

cpu_count="$(cpu_count)"
multiplier=1  # doesn't get faster increasing this in tests, perhaps even slightly slower due to context switching
parallelism="$((cpu_count * multiplier))"

echo "found $cpu_count cores, running $parallelism parallel jobs"
echo

# export functions to use in parallel
export -f check_yaml
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
    section2 "All YAML files passed syntax check"
else
    echo "ERROR: $count broken yaml files detected!" >&2
    echo >&2
    section2 "YAML checks failed"
    exit 1
fi
