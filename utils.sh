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

[ "${bash_tools_utils_imported:-0}" = 1 ] && return
bash_tools_utils_imported=1

. "$srcdir/docker.sh"
. "$srcdir/perl.sh"

export TRAP_SIGNALS="INT QUIT TRAP ABRT TERM EXIT"

die(){
    echo "$@"
    exit 1
}

hr(){
    echo "================================================================================"
}

hr2(){
    echo "=================================================="
}

hr3(){
    echo "========================================"
}

section(){
    hr
    "`dirname ${BASH_SOURCE[0]}`/center.sh" "$@"
    hr
    if [ -n "${PROJECT:-}" ]; then
        echo "PROJECT: $PROJECT"
    fi
    if is_inside_docker; then
        echo "(running inside docker)"
    fi
    echo
}

section2(){
    hr2
    hr2echo "$@"
    hr2
    echo
}

section3(){
    hr3
    hr3echo "$@"
    hr3
    echo
}

hr2echo(){
    "`dirname ${BASH_SOURCE[0]}`/center.sh" "$@" 50
}

hr3echo(){
    "`dirname ${BASH_SOURCE[0]}`/center.sh" "$@" 40
}

#set +o pipefail
#spark_home="$(ls -d tests/spark-*-bin-hadoop* 2>/dev/null | head -n 1)"
#set -o pipefail
#if [ -n "$spark_home" ]; then
#    export SPARK_HOME="$spark_home"
#fi

type isExcluded &>/dev/null || . "$srcdir/excluded.sh"

check_output(){
    local expected="$1"
    local cmd="${@:2}"
    # do not 2>&1 it will cause indeterministic output even with python -u so even tail -n1 won't work
    echo "check_output:  $cmd"
    echo "expecting:     $expected"
    local output="$($cmd)"
    # intentionally not quoting so that we can use things like google* glob matches for google.com and google.co.uk
    if [[ "$output" = $expected ]]; then
        echo "SUCCESS:       $output"
    else
        die "FAILED:        $output"
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

# =================================
#
# these functions are too clever and dynamic but save a lot of duplication in nagios-plugins test_*.sh scripts
#
print_debug_env(){
    echo
    echo "Environment for Debugging:"
    echo
    if [ -n "${version:-}" ]; then
        echo "version: $version"
        echo
    fi
    # multiple name support for MySQL + MariaDB variables
    for name in $@; do
        name="$(tr 'a-z' 'A-Z' <<< "$name")"
        #eval echo "export ${name}_PORT=$`echo ${name}_PORT`"
        # instead of just name_PORT, find all PORTS in environment and print them
        # while read line to preserve CASSANDRA_PORTS=7199 9042
        env | egrep "^$name.*_" | grep -v DEFAULT | sort | while read env_var; do
            # sed here to quote export CASSANDRA_PORTS=7199 9042 => export CASSANDRA_PORTS="7199 9042"
            eval echo "export $env_var" | sed 's/=/="/;s/$/"/'
        done
        echo
    done
}

trap_debug_env(){
    local name="$1"
    trap 'result=$?; print_debug_env '"$*"'; untrap; exit $result' $TRAP_SIGNALS
}

run_test_versions(){
    local name="$1"
    local test_func="$(tr 'A-Z' 'a-z' <<< "test_${name/ /_}")"
    local VERSIONS="$(tr 'a-z' 'A-Z' <<< "${name/ /_}_VERSIONS")"
    test_versions="$(eval ci_sample $`echo $VERSIONS`)"
    for version in $test_versions; do
        eval "$test_func" "$version"
    done

    if [ -n "${NOTESTS:-}" ]; then
        print_port_mappings "$name"
    else
        untrap
        echo "All $name tests succeeded for versions: $test_versions"
    fi
    echo
}

# =================================

timestamp(){
    printf "%s" "`date '+%F %T'`  $*" >&2
    [ $# -gt 0 ] && printf "\n" >&2
}
tstamp(){ timestamp "$@"; }

start_timer(){
    tstamp "Starting...
"
    date '+%s'
}

time_taken(){
    echo
    local start_time="$1"
    shift
    local time_taken
    local msg="${@:-Completed in}"
    tstamp "Finished"
    echo
    local end_time="$(date +%s)"
    # if start and end time are the same let returns exit code 1
    let time_taken=$end_time-$start_time || :
    echo "$msg $time_taken secs"
    echo
}

when_ports_available(){
    local max_secs="$1"
    local host="$2"
    local ports="${@:3}"
    local retry_interval=1
    if [ -z "$max_secs" ]; then
        echo 'when_ports_available: max_secs $1 not set'
        exit 1
    elif [ -z "$host" ]; then
        echo 'when_ports_available: host $2 not set'
        exit 1
    elif [ -z "$ports" ]; then
        echo 'when_ports_available: ports $3 not set'
        exit 1
    fi
    local max_tries=$(($max_secs / $retry_interval))
    # Linux nc doens't have -z switch like Mac OSX version
    local nc_cmd="nc -vw $retry_interval $host <<< ''"
    cmd=""
    for x in $ports; do
        cmd="$cmd $nc_cmd $x &>/dev/null && "
    done
    local cmd="${cmd% && }"
    plural_str $ports
    echo "waiting for port$plural '$ports' to become available, will try up to $max_tries times at $retry_interval sec intervals"
    echo "cmd: ${cmd// \&\>\/dev\/null}"
    local found=0
    if which nc &>/dev/null; then
        for((i=1; i <= $max_tries; i++)); do
            timestamp "$i trying host '$host' port(s) '$ports'"
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

when_url_content(){
    local max_secs="$1"
    local url="$2"
    local expected_regex="$3"
    local retry_interval=1
    if [ -z "$max_secs" ]; then
        echo 'when_url_content: max_secs $1 not set'
        exit 1
    elif [ -z "$url" ]; then
        echo 'when_url_content: url $2 not set'
        exit 1
    elif [ -z "$expected_regex" ]; then
        echo 'when_url_content: expected content $3 not set'
        exit 1
    fi
    local max_tries=$(($max_secs / $retry_interval))
    echo "waiting up to $max_secs secs for HTTP interface to come up with expected regex content: '$expected_regex'"
    found=0
    for((i=1; i <= $max_tries; i++)); do
        timestamp "$i trying $url"
        if curl -s -L "$url" | grep -q -- "$expected_regex"; then
            echo "URL content detected '$expected_regex'"
            found=1
            break
        fi
        sleep 1
    done
    if [ $found -eq 1 ]; then
        timestamp "URL content found after $i secs"
    else
        timestamp "URL content still not available after '$max_secs' secs, giving up waiting"
    fi
}

# restore original srcdir
srcdir="$srcdir_bash_tools_utils"
