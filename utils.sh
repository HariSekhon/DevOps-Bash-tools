#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2015-05-25 01:38:24 +0100 (Mon, 25 May 2015)
#
#  https://github.com/harisekhon/pytools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help improve or steer this or other code I publish
#
#  https://www.linkedin.com/in/harisekhon
#

set -eu
[ -n "${DEBUG:-}" ] && set -x
srcdir_bash_tools_utils="${srcdir:-}"
srcdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

export TRAP_SIGNALS="INT QUIT TRAP ABRT TERM EXIT"

die(){
    echo "$@"
    exit 1
}

hr(){
    echo "================================================================================"
}

section(){
    hr
    "`dirname ${BASH_SOURCE[0]}`/center80.sh" "$@"
    hr
    echo
}

# TODO:
#export SPARK_HOME="$(ls -d tests/spark-*-bin-hadoop* | head -n 1)"

type isExcluded &>/dev/null || . "$srcdir/excluded.sh"

check_output(){
    local expected="$1"
    local cmd="${@:2}"
    # do not 2>&1 it will cause indeterministic output even with python -u so even tail -n1 won't work
    local output="$($cmd)"
    if [ -n "${DEBUG:-}" ]; then
        echo "full debug output: $output"
    fi
    # intentionally not quoting so that we can use things like google* glob matches for google.com and google.co.uk
    if [[ "$output" = $expected ]]; then
        echo "SUCCESS: got expected output '$output'"
    else
        die "FAILED: got '$output', expected '$expected'"
    fi
    echo
}

check_exit_code(){
    local exit_code=$?
    local expected_exit_codes="$@"
    local failed=1
    for e in $expected_exit_codes; do
        if [ $exit_code = $e ]; then
            failed=0
        fi
    done
    if [ $failed != 0 ]; then
        echo "WRONG EXIT CODE RETURNED! Expected: '$expected_exit_codes', got: '$exit_code'"
        exit 1
    fi
}

is_linux(){
    if [ "$(uname -s)" = "Linux" ]; then
        return 0
    else
        return 1
    fi
}

is_mac(){
    if [ "$(uname -s)" = "Darwin" ]; then
        return 0
    else
        return 1
    fi
}

is_jenkins(){
    if [ -n "${JENKINS_URL:-}" ]; then
        return 0
    else
        return 1
    fi
}

is_travis(){
    if [ -n "${TRAVIS:-}" ]; then
        return 0
    else
        return 1
    fi
}

is_CI(){
    if [ -n "${CI:-}" -o -n "${CI_NAME:-}" ] || is_jenkins || is_travis; then
        return 0
    else
        return 1
    fi
}

if is_travis; then
    #export DOCKER_HOST="${DOCKER_HOST:-localhost}"
    export HOST="${HOST:-localhost}"
fi

if is_travis; then
    sudo=sudo
else
    sudo=""
fi

# useful for cutting down on number of noisy docker tests which take a long time but more importantly
# cause the CI builds to fail with job logs > 4MB
ci_sample(){
    local versions="$@"
    if [ -n "${SAMPLE:-}" ] || is_CI; then
        if [ -n "$versions" ]; then
            local a
            IFS=' ' read -r -a a <<< "$versions"
            local highest_index="${#a[@]}"
            local random_index="$(($RANDOM % $highest_index))"
            echo "${a[$random_index]}"
            return 0
        else
            return 1
        fi
    else
        if [ -n "$versions" ]; then
            echo "$versions"
        fi
    fi
    return 0
}

untrap(){
    trap - $TRAP_SIGNALS
}

plural(){
    plural="s"
    local num="${1:-}"
    if [ "$num" = 1 ]; then
        plural=""
    fi
}

plural_str(){
    local parts=($@)
    plural ${#parts[@]}
}

timestamp(){
    printf "%s" "`date '+%F %T'`  $*";
    [ $# -gt 0 ] && printf "\n"
}

when_ports_available(){
    local max_secs="$1"
    local host="$2"
    local ports="${@:3}"
    local retry_interval=1
    local max_tries=$(($max_secs / $retry_interval))
    local nc_cmd="nc -z -G $retry_interval $host"
    cmd=""
    for x in $ports; do
        cmd="$cmd $nc_cmd $x &>/dev/null && "
    done
    local cmd="${cmd% && }"
    plural_str $ports
    echo "waiting for port$plural '$ports' to become available, will try up to $max_tries times at $retry_interval sec intervals"
    echo "cmd: $cmd"
    local found=0
    if which nc &>/dev/null; then
        for((i=0; i < $max_tries; i++)); do
            timestamp "trying host '$host' port(s) '$ports'"
            if eval $cmd; then
                found=1
                break
            fi
            sleep 1
        done
        if [ $found -eq 1 ]; then
            timestamp "host '$host' port$plural '$ports' available after $i secs"
        else
            timestamp "host '$host' port$plural '$ports' still not available after '$max_secs' secs, giving up waiting"
        fi
    else
        echo "'nc' command not found, sleeping for '$max_secs' secs instead"
        sleep "$max_secs"
    fi
}

# restore original srcdir
srcdir="$srcdir_bash_tools_utils"
