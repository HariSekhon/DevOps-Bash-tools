#!/usr/bin/env bash
#  shellcheck disable=SC2128,SC2230,SC1090
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2015-05-25 01:38:24 +0100 (Mon, 25 May 2015)
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
srcdir_bash_tools_utils="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ "${bash_tools_utils_imported:-0}" = 1 ]; then
    return 0
fi
bash_tools_utils_imported=1

. "$srcdir_bash_tools_utils/utils-bourne.sh"

export PATH="$PATH:/usr/local/bin"

. "$srcdir_bash_tools_utils/ci.sh"
. "$srcdir_bash_tools_utils/docker.sh"
. "$srcdir_bash_tools_utils/os.sh"
. "$srcdir_bash_tools_utils/mac.sh"
. "$srcdir_bash_tools_utils/perl.sh"
. "$srcdir_bash_tools_utils/../.bash.d/colors.sh"
#. "$srcdir_bash_tools_utils/python.sh"
#. "$srcdir_bash_tools_utils/ruby.sh"

# consider adding ERR as set -e handler, not inherited by shell funcs / cmd substitutions / subshells without set -E
export TRAP_SIGNALS="INT QUIT TRAP ABRT TERM EXIT"

# prevents illegal byte encoding errors when piping to filenames with unicode characters
# doesn't work in CentOS 8 docker, gets this error
# bash: warning: setlocale: LC_ALL: cannot change locale (en_US.UTF-8)
#export LC_ALL=en_US.UTF-8
# but this works
export LANG=en_US.UTF-8

open(){
    if is_mac; then
        command open "$@"
    elif type -P xdg-open &>/dev/null; then
        xdg-open "$@"
    elif sensible-browser &>/dev/null; then
        sensible-browser "$@"
    elif x-www-browser &>/dev/null; then
        x-www-browser "$@"
    elif gnome-open &>/dev/null; then
        gnome-open "$@"
    else
        echo "Neither 'xdg-open' nor 'sensible-browser' were found in \$PATH - install one of them to automatically open this URL:"
        echo
        echo "$*"
        echo
    fi
}

if [ -z "${run_count:-}" ]; then
    run_count=0
fi
if [ -z "${total_run_count:-}" ]; then
    total_run_count=0
fi

# ERE format (egrep / grep -E)
#
# used in client scripts
# shellcheck disable=SC2034
domain_regex='\b(([A-Za-z0-9](-?[A-Za-z0-9])*)\.)+[A-Za-z]{2,}\b'
# shellcheck disable=SC2034
email_regex='\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}\b'
# shellcheck disable=SC2034
ip_regex='[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}'
# shellcheck disable=SC2034
url_regex='https?://[[:alnum:]@%\._\+~#?&/=-]+'  # TODO: improve

wrong_port=1111

die(){
    echo "$@" >&2
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
    name="$*"
    hr
    "$srcdir_bash_tools_utils/../bin/center.sh" "$@"
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
    "$srcdir_bash_tools_utils/../bin/center.sh" "$@" 50
}

hr3echo(){
    "$srcdir_bash_tools_utils/../bin/center.sh" "$@" 40
}

#set +o pipefail
#spark_home="$(ls -d tests/spark-*-bin-hadoop* 2>/dev/null | head -n 1)"
#set -o pipefail
#if [ -n "$spark_home" ]; then
#    export SPARK_HOME="$spark_home"
#fi

# shellcheck disable=SC1090
type isExcluded &>/dev/null || . "$srcdir_bash_tools_utils/excluded.sh"


check_bin(){
    local bin="${1:-}"
    if ! type -P "$bin" &>/dev/null; then
        echo "command '$bin' not found in \$PATH ($PATH)" >&2
        if is_CI; then
            timestamp "Running in CI, searching entire system for '$bin'"
            find / -type f -name "$bin" 2>/dev/null
        fi
        exit 1
    fi
}


check_output(){
    local expected="$1"
    # shellcheck disable=SC2178
    local cmd="${*:2}"
    # do not 2>&1 it will cause indeterministic output even with python -u so even tail -n1 won't work
    echo "check_output:  $cmd"
    echo "expecting:     $expected"
    local output
    output="$($cmd)"
    # intentionally not quoting so that we can use things like google* glob matches for google.com and google.co.uk
    # shellcheck disable=SC2053
    if [[ "$output" = $expected ]]; then
        echo "SUCCESS:       $output"
    else
        die "FAILED:        $output"
    fi
    echo
}

check_exit_code(){
    local exit_code=$?
    local expected_exit_codes
    expected_exit_codes="$*"
    local failed
    failed=1
    for e in $expected_exit_codes; do
        if [ "$exit_code" = "$e" ]; then
            echo "got expected exit code: $e"
            failed=0
        fi
    done
    if [ "$failed" != 0 ]; then
        echo "WRONG EXIT CODE RETURNED! Expected: '$expected_exit_codes', got: '$exit_code'" >&2
        return 1
    fi
}

tick_msg(){
    # defined in .bash.d/colors.sh
    # shellcheck disable=SC2154
    echo -e "${bldgrn}✓ ${txtrst}$*"
}

cpu_count(){
    local cpu_count
    if type -P nproc &>/dev/null; then
        nproc
        return
    elif is_mac; then
        cpu_count="$(sysctl -n hw.ncpu)"
    else
        #cpu_count="$(awk '/^processor/ {++n} END {print n+1}' /proc/cpuinfo)"
        cpu_count="$(grep -c '^processor[[:space:]]*:' /proc/cpuinfo)"
    fi
    echo "$cpu_count"
}

has_terminal(){
    [ -t 0 ]
}

is_tty(){
    has_terminal
}

is_piped(){
    ! [ -t 1 ]
}

# beware this results false in scripts, has_terminal is probably what you want
is_interactive(){
    if [ -n "${PS1:-}" ]; then
        return 0
    fi
    case "$-" in
        *i*) return 0
    esac
    return 1
}

# XXX: there are other tarball extensions for other compression algorithms but these are the 2 very standard ones we always use: gzip or bz2
has_tarball_extension(){
    local filename="$1"
    # .tgz
    # .tbz
    # .tar.gz
    # .tar.bz2
    #[[ "$filename" =~ \.(tgz|tbz|tar(\.(gz|bz2))?)$ ]]
    has_tarball_gzip_extension "$filename" ||
    has_tarball_bzip2_extension "$filename"
}

has_tarball_gzip_extension(){
    local filename="$1"
    # .tgz
    # .tar.gz
    [[ "$filename" =~ \.(tgz|tar\.gz)$ ]]
}

has_tarball_bzip2_extension(){
    local filename="$1"
    # .tbz
    # .tar.bz2
    [[ "$filename" =~ \.(tbz|tar\.bz2)$ ]]
}

get_os(){
    local os
    os="$(uname -s | tr '[:upper:]' '[:lower:]')"
    if [ -n "${OS_DARWIN:-}" ]; then
        if is_mac; then
            os="$OS_DARWIN"
        fi
    elif [ -n "${OS_LINUX:-}" ]; then
        if is_linux; then
            os="$OS_LINUX"
        fi
    fi
    echo "$os"
}

get_arch(){
    local arch
    arch="$(uname -m)"
    if [ "$arch" = x86_64 ]; then
        arch=amd64  # files are conventionally usually named amd64 not x86_64
    fi
    #if [ "$arch" = aarch64 ]; then
    #    arch=arm64
    #fi
    if [ -n "${ARCH_X86_64:-}" ]; then
        if [ "$arch" = amd64 ] || [ "$arch" = x86_64 ]; then
            arch="$ARCH_X86_64"
        fi
    fi
    if [ -n "${ARCH_X86:-}" ]; then
        if [ "$arch" = i386 ]; then
            arch="$ARCH_X86"
        fi
    fi
    if [ -n "${ARCH_ARM64:-}" ]; then
        if [ "$arch" = arm64 ]; then
            arch="$ARCH_ARM64"
        fi
    fi
    if [ -n "${ARCH_ARM:-}" ]; then
        if [ "$arch" = arm ]; then
            arch="$ARCH_ARM"
        fi
    fi
    if [ -n "${ARCH_OVERRIDE:-}" ]; then
        arch="$ARCH_OVERRIDE"
    fi
    echo "$arch"
}

curl(){
    local opts=()
    if is_piped || is_CI; then
        opts+=(-sSf)
    fi
    command curl ${opts:+"${opts[@]}"} "$@"
}

wget(){
    local opts=(-c)
    if is_piped || is_CI; then
        opts+=(--no-verbose)  # -q suppresses the error messages we need to debug, leading to silent exits
    fi
    command wget ${opts:+"${opts[@]}"} "$@"
}

download(){
    local url="$1"
    local download_file="${2:-${url##*/}}"
    if type -P wget &>/dev/null; then
        wget -O "$download_file" "$url"
    elif type -P curl &>/dev/null; then
        curl -sSLf -o "$download_file" "$url"
    else
        die "wget / curl not installed - cannot download"
    fi
}

is_latest_version(){
    # permit .* as we often replace version if latest with .* to pass regex version tests, which allows this to be called any time
    if [ "$version" = "latest" ] || [ "$version" = ".*" ]; then
        return 0
    fi
    return 1
}

curl_version(){
    curl --version | awk '{print $2; exit}' | grep -Eom1 '[[:digit:]]+\.[[:digit:]]+'
}
is_curl_min_version(){
    # shellcheck disable=SC2178
    local target_version="$1"
    local curl_version
    curl_version="$(curl_version)"
    #bc_bool "$curl_version >= $target_version"
    is_min_version "$curl_version" "$target_version"
}

golang_version(){
    go version | grep -Eom1 '[[:digit:]]+\.[[:digit:]]+'
}
go_version(){
    golang_version
}

is_golang_min_version(){
    # shellcheck disable=SC2178
    local target_version="$1"
    local go_version
    go_version="$(go_version)"
    is_min_version "$go_version" "$target_version"
}
is_go_min_version(){
    is_golang_min_version "$@"
}

is_min_version(){
    local IFS=.
    # shellcheck disable=SC2206
    local version=($1)
    # shellcheck disable=SC2206
    local target_version=($2)
    local i
    for ((i=0; i < ${#target_version[@]}; i++)); do
        if [[ -z "${version[i]:-}" ]]; then
            # fill empty fields with zeros
            version[i]=0
        fi
        if (( target_version[i] > version[i] )); then
            return 1
        fi
    done
    return 0
}

is_semver(){
    # shellcheck disable=SC2178
    local version="$1"
    local allowed_prefix="${2:-v}"
    [[ "$version" =~ ^${allowed_prefix}?[[:digit:]]+\.[[:digit:]]+\.[[:digit:]]+$ ]]
}

bc_bool(){
    # bc returns 1 when expression is true and zero otherwise, but this is counterintuitive
    # to regular shell scripting, let's use the actual output 1 for true, 0 for false
    # echo rather than <<< to show expression to evaluate in trace debugging
    echo "$@" | bc -l | grep -q 1
}

curl_api_opts(){
    # arrays can't be exported so have to pass as a string and then split to array
    if [ -n "${CURL_OPTS:-}" ]; then
        read -r -a CURL_OPTS <<< "${CURL_OPTS[@]}" # this @ notation works for both strings and arrays in case a future version of bash do export arrays this should still work
    else
        #read -r -a CURL_OPTS <<< "-sS --fail --connect-timeout 10"
        CURL_OPTS=(-sS --fail --connect-timeout 10)
    fi

    # case insensitive regex matching
    shopt -s nocasematch
    # XML by default :-/
    if ! [[ "$* ${CURL_OPTS[*]:-}" =~ Accept: ]]; then
        CURL_OPTS+=(-H "Accept: application/json")
    fi
    if ! [[ "$* ${CURL_OPTS[*]:-}" =~ Content-Type: ]]; then
        CURL_OPTS+=(-H "Content-Type: application/json")
    fi
    # unset to return to default setting for safety to avoid hard to debug changes of behaviour elsewhere
    shopt -u nocasematch
    export CURL_OPTS
}

# useful for cutting down on number of noisy docker tests which take a long time but more importantly
# cause the CI builds to fail with job logs > 4MB
ci_sample(){
    local versions
    versions="${*:-}"
    # longer time limits on GitHub Workflows than other CI systems like Travis so don't sample, run everything
    if is_github_workflow; then
        echo "$versions"
    elif [ -n "${SAMPLE:-}" ] || is_CI; then
        if [ -n "$versions" ]; then
            local a
            IFS=' ' read -r -a a <<< "$versions"
            local highest_index
            highest_index="${#a[@]}"
            local random_index
            random_index="$((RANDOM % highest_index))"
            echo "${a[$random_index]}"
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

trap_cmd(){
    # shellcheck disable=SC2064,SC2086
    trap "$@" $TRAP_SIGNALS
}

untrap(){
    # shellcheck disable=SC2086
    trap - $TRAP_SIGNALS
}

plural(){
    plural="s"
    local num
    num="${1:-}"
    if [ "$num" = 1 ]; then
        plural=""
    fi
}

plural_str(){
    local parts=("$@")
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
    if [ -n "${VERSION:-}" ]; then
        echo "VERSION: $VERSION"
        echo
    fi
    if [ -n "${version:-}" ]; then
        echo "version: $version"
        echo
    fi
    # multiple name support for MySQL + MariaDB variables
    for name in "$@"; do
        name="$(tr '[:lower:]' '[:upper:]' <<< "$name")"
        #eval echo "export ${name}_PORT=$`echo ${name}_PORT`"
        # instead of just name_PORT, find all PORTS in environment and print them
        # while read line to preserve CASSANDRA_PORTS=7199 9042
        env | grep -E -- "^$name.*_" | grep -v -e 'DEFAULT=' -e 'VERSIONS=' | sort | while read -r env_var; do
            # sed here to quote export CASSANDRA_PORTS=7199 9042 => export CASSANDRA_PORTS="7199 9042"
            eval echo "'export $env_var'" | sed 's/=/="/;s/$/"/'
        done
        echo
    done
}

trap_debug_env(){
    local name
    name="$1"
    # stop CI systems from running out of space due to accumulated docker images as that causes build failures
    if is_CI &&
       ! type trap_function &>/dev/null &&
       type docker_image_cleanup &>/dev/null; then
        trap_function(){
            # shellcheck disable=SC2317
            docker_image_cleanup
        }
    fi
    # shellcheck disable=SC2086,SC2154
    trap 'result=$?; type trap_function >/dev/null 2>/dev/null && trap_function; print_debug_env '"$*"'; untrap; exit $result' $TRAP_SIGNALS
}

is_debug(){
    [ -n "${DEBUG:-}" ]
}

is_verbose(){
    [ -n "${VERBOSE:-}" ]
}

pass(){
    read_secret "password"
    export PASSWORD="$secret"
}

read_secret(){
    secret=""
    prompt="Enter ${1:-secret value}: "
    # doesn't echo any characters to the screen even in commands
    #stty -echo
    # this gives stars feedback which is nicer
    while IFS= read -p "$prompt" -r -s -n 1 char; do
        if [[ "$char" == $'\0' ]]; then
            break
        fi
        prompt='*'
        secret="${secret}${char}"
    done
    #stty echo
    echo
    export secret
}

if is_mac; then
    awk(){
        # needed for awk -v IGNORECASE=1 to work for case insensitive regex
        command gawk "$@"
    }
    grep(){
        command ggrep "$@"
    }
    readlink(){
        command greadlink "$@"
    }
    date(){
        command gdate "$@"
    }
    sed(){
        command gsed "$@"
    }
    xargs(){
        command gxargs "$@"
    }
fi

# fails interactive import without this
function run++ () {
    #if [[ "$run_count" =~ ^[[:digit:]]+$ ]]; then
        ((run_count+=1))
    #fi
}

run(){
    if [ -n "${ERRCODE:-}" ]; then
        run_fail "$ERRCODE" "$@"
    else
        run++
        echo "$@"
        "$@"
        # run_fail does it's own hr
        hr
    fi
}

run_conn_refused(){
    echo "checking connection refused:"
    ERRCODE=2 run_grep "Connection refused|Can't connect|Could not connect to|ConnectionClosed" "$@" -H localhost -P "$wrong_port"
}

run_404(){
    echo "checking 404 Not Found:"
    ERRCODE=2 run_grep "404 Not Found" "$@"
}

run_timeout(){
    echo "checking timeout:"
    ERRCODE=3 run_grep "timed out" "$@"
}

run_usage(){
    echo "checking usage / parsing:"
    ERRCODE=3 run_grep "usage: " "$@"
}

run_output(){
    local expected_output
    expected_output="$1"
    shift
    run++
    echo "$@"
    set +e
    check_output "$expected_output" "$@"
    set -e
    hr
}

run_fail(){
    local expected_exit_code
    expected_exit_code="$1"
    shift
    run++
    echo "$@"
    set +e
    "$@"
    # intentionally don't quote $expected_exit_code so that we can pass multiple exit codes through first arg and have them expanded here
    # shellcheck disable=SC2086
    check_exit_code $expected_exit_code || exit 1
    set -e
    hr
}

run_grep(){
    local egrep_pattern
    egrep_pattern="$1"
    shift
    expected_exit_code="${ERRCODE:-0}"
    run++
    echo "$@"
    set +eo pipefail
    # pytools programs write to stderr, must test this for connection refused type information
    output="$("$@" 2>&1)"
    if ! check_exit_code "$expected_exit_code"; then
        echo "$output"
        exit 1
    fi
    set -e
    # this must be egrep -i because (?i) modifier does not work
    echo "> | tee /dev/stderr | grep -Eqi '$egrep_pattern'"
    echo "$output" | tee /dev/stderr | grep -Eqi -- "$egrep_pattern"
    set -o pipefail
    hr
}

run_test_versions(){
    local name
    name="$1"
    local test_func
    test_func="$(tr '[:upper:]' '[:lower:]' <<< "test_${name/ /_}")"
    local VERSIONS
    VERSIONS="$(tr '[:lower:]' '[:upper:]' <<< "${name/ /_}_VERSIONS")"
    # shellcheck disable=SC2006
    local test_versions
    # shellcheck disable=SC2046,SC2006,SC2116
    test_versions="$(eval ci_sample $`echo "$VERSIONS"`)"
    local test_versions_ordered
    test_versions_ordered="$test_versions"
    if [ -z "${NO_VERSION_REVERSE:-}" ]; then
        # tail -r works on Mac but not Travis CI Ubuntu Trusty
        # shellcheck disable=SC2119
        test_versions_ordered="$(tr ' ' '\n' <<< "$test_versions" | tac | tr '\n' ' ')"
    fi
    local start_time
    start_time="$(start_timer "$name tests")"
    for version in $test_versions_ordered; do
        version_start_time="$(start_timer "$name test for version:  $version")"
        run_count=0
        eval "$test_func" "$version"
        if [ $run_count -eq 0 ]; then
            echo "NO TEST RUNS DETECTED!" >&2
            exit 1
        fi
        ((total_run_count+=run_count))
        time_taken "$version_start_time" "$name version '$version' tests completed in"
        echo
    done

    if [ -n "${NOTESTS:-}" ]; then
        print_debug_env "$name"
    else
        untrap
        timestamp "All $name tests succeeded for versions: $test_versions"
        echo >&2
        timestamp "Total Tests run: $total_run_count"
        time_taken "$start_time" "All version tests for $name completed in"
        echo
    fi
    echo
}

# examples:
#
# #  run: kubectl apply -f file.yaml
# // run: go run file.go
# -- run: psql -f file.sql
parse_run_args(){
    perl -ne 'if(/^\s*(#|\/\/|--)\s*run:/){s/^\s*(#|\/\/)\s*run:\s*//; print $_; exit}' "$@"
}

# example:
#
# lint: k8s
parse_lint_hint(){
    perl -ne 'if(/^\s*(#|\/\/|--)\s*lint:/){s/^\s*(#|\/\/)\s*lint:\s*//; print $_; exit}' "$@"
}

# =================================

stat_bytes(){
    if is_mac; then
        stat -f %z "$@"
    else
        stat -c %s "$@"
    fi
}

timestamp(){
    printf "%s  %s" "$(date '+%F %T')" "$*" >&2
    if [ $# -gt 0 ]; then
        printf '\n' >&2
    fi
}
tstamp(){ timestamp "$@"; }

seconds_to_hours(){
    local secs="$1"
    printf '%d:%02d:%02d\n' $((secs/3600)) $((secs%3600/60)) $((secs%60))
}

warn(){
    timestamp "WARNING: $*"
}
warning(){
    warn "$@"
}

error(){
    timestamp "ERROR: $*"
}

log(){
    if is_verbose; then
        timestamp "$@"
    fi
}

start_timer(){
    tstamp "Starting $*
"
    date '+%s'
}

time_taken(){
    echo
    local start_time
    # workaround if 2>&1 captures message from start_timer and only want final epoch timestamp
    start_time="${1//*[[:space:]]}"
    shift
    local time_taken
    local msg
    msg="${*:-Completed in}"
    tstamp "Finished"
    echo
    local end_time
    end_time="$(date +%s)"
    time_taken="$((end_time - start_time))"
    echo "$msg $time_taken secs"
    echo
}

# args may be passed in client code
# shellcheck disable=SC2120
startupwait(){
    startupwait="${1:-30}"
    if is_CI; then
        ((startupwait*=2))
    fi
}
# trigger to set a sensible default if we forget, as it is used
# as a fallback in when_ports_available and when_url_content below
# shellcheck disable=SC2119
startupwait

next_available_port(){
    local local_port="${1:-1024}"
    local next_port
    while netstat -lnt | grep -q ":$local_port "; do
        next_port="$((local_port + 1))"
        timestamp "Local port '$local_port' in use, trying next port '$next_port'"
        local_port="$next_port"
        if [ "$local_port" -gt 65535 ]; then
            die "ERROR: No local port found available"
        fi
    done
    echo "$local_port"
}

when_ports_available(){
    local max_secs="${1:-}"
    if ! [[ "$max_secs" =~ ^[[:digit:]]+$ ]]; then
        max_secs="$startupwait"
    else
        shift
    fi
    local host="${1:-}"
    local ports="${*:2}"
    local retry_interval="${RETRY_INTERVAL:-1}"
    if [ -z "$host" ]; then
        echo "$FUNCNAME: host \$2 not set" >&2
        exit 1
    elif [ -z "$ports" ]; then
        echo "$FUNCNAME: ports \$3 not set" >&2
        exit 1
    else
        for port in $ports; do
            if ! [[ "$port" =~ ^[[:digit:]]+$ ]]; then
                echo "$FUNCNAME: invalid non-numeric port argument '$port'" >&2
                exit 1
            fi
        done
    fi
    if ! [[ "$retry_interval" =~ ^[[:digit:]]+$ ]]; then
        echo "$FUNCNAME: invalid non-numeric \$RETRY_INTERVAL '$retry_interval'" >&2
        exit 1
    fi
    # Mac nc doesn't have -z switch like Linux GNU version and we can't rely on one being found first in $PATH
    #local nc_cmd="nc -vw $retry_interval $host <<< ''"
    #cmd=""
    #for x in $ports; do
    #    cmd="$cmd $nc_cmd $x &>/dev/null && "
    #done
    #local cmd="${cmd% && }"
    # shellcheck disable=SC2086
    plural_str $ports
    timestamp "waiting for up to $max_secs secs for port$plural '$ports' to become available, retrying at $retry_interval sec intervals"
    #echo "cmd: ${cmd// \&\>\/dev\/null}"
    local found=0
    if type -P nc &>/dev/null; then
        # Mac nc doesn't have -z switch like Linux GNU version
        nc_opts=""
        if nc --help 2>&1 | grep -q GNU; then
            nc_opts="-z"
        fi
        try_number=0
        # special built-in that increments for script runtime, reset to zero exploit it here
        SECONDS=0
        # bash will interpolate from string for correct numeric comparison and safer to quote vars
        while [ "$SECONDS" -lt "$max_secs" ]; do
            ((try_number+=1))
            for port in $ports; do
                if ! nc -v -w "$retry_interval" $nc_opts "$host" "$port" < /dev/null &>/dev/null; then
                    timestamp "$try_number waiting for host '$host' port '$port'"
                    sleep "$retry_interval"
                    break
                fi
                found=1
            done
            if [ $found -eq 1 ]; then
                break
            fi
        done
        if [ $found -eq 1 ]; then
            timestamp "host '$host' port$plural '$ports' available after $SECONDS secs"
        else
            timestamp "host '$host' port$plural '$ports' still not available after '$max_secs' secs, giving up waiting"
            return 1
        fi
    else
        timestamp "WARNING: nc command not found in \$PATH, cannot check port availability, skipping port checks, tests may fail due to race conditions on service availability"
        timestamp "sleeping for '$max_secs' secs instead"
        sleep "$max_secs"
    fi
}

# Do not use this on docker containers
# docker mapped ports still return connection succeeded even when the process mapped to them is no longer listening inside the container!
# must be the result of docker networking
when_ports_down(){
    local max_secs="${1:-}"
    if ! [[ "$max_secs" =~ ^[[:digit:]]+$ ]]; then
        max_secs="$startupwait"
    else
        shift
    fi
    local host="${1:-}"
    local ports="${*:2}"
    local retry_interval="${RETRY_INTERVAL:-1}"
    if [ -z "$host" ]; then
        echo "$FUNCNAME: host \$2 not set" >&2
        return 1
    elif [ -z "$ports" ]; then
        echo "$FUNCNAME: ports \$3 not set" >&2
        return 1
    else
        for port in $ports; do
            if ! [[ "$port" =~ ^[[:digit:]]+$ ]]; then
                echo "$FUNCNAME: invalid non-numeric port argument '$port'" >&2
                return 1
            fi
        done
    fi
    if ! [[ "$retry_interval" =~ ^[[:digit:]]+$ ]]; then
        echo "$FUNCNAME: invalid non-numeric \$RETRY_INTERVAL '$retry_interval'" >&2
        return 1
    fi
    #local max_tries=$(($max_secs / $retry_interval))
    # Mac nc doesn't have -z switch like Linux GNU version
    nc_opts=""
    if nc --help 2>&1 | grep -q GNU; then
        nc_opts="-z"
    fi
    local nc_cmd="nc -v -w $retry_interval $nc_opts $host < /dev/null"
    # shellcheck disable=SC2178
    local cmd=""
    for x in $ports; do
        # shellcheck disable=SC2178
        cmd="$cmd ! $nc_cmd $x &>/dev/null && "
    done
    # shellcheck disable=SC2178
    cmd="${cmd% && }"
    # shellcheck disable=SC2086
    plural_str $ports
    timestamp "waiting for up to $max_secs secs for port$plural '$ports' to go down, retrying at $retry_interval sec intervals"
    timestamp "cmd: ${cmd// \&\>\/dev\/null}"
    local down=0
    if type -P nc &>/dev/null; then
        #for((i=1; i <= $max_tries; i++)); do
        try_number=0
        # special built-in that increments for script runtime, reset to zero exploit it here
        SECONDS=0
        # bash will interpolate from string for correct numeric comparison and safer to quote vars
        while [ "$SECONDS" -lt "$max_secs" ]; do
            ((try_number+=1))
            timestamp "$try_number trying host '$host' port(s) '$ports'"
            if eval "$cmd"; then
                down=1
                break
            fi
            sleep "$retry_interval"
        done
        if [ $down -eq 1 ]; then
            timestamp "host '$host' port$plural '$ports' down after $SECONDS secs"
        else
            timestamp "host '$host' port$plural '$ports' still not down after '$max_secs' secs, giving up waiting"
            return 1
        fi
    else
        timestamp "WARNING: nc command not found in \$PATH, cannot check for ports down, skipping port checks, tests may fail due to race conditions on service availability"
        timestamp "sleeping for '$max_secs' secs instead"
        sleep "$max_secs"
    fi
}

when_url_content(){
    local max_secs="${1:-}"
    if ! [[ "$max_secs" =~ ^[[:digit:]]+$ ]]; then
        max_secs="$startupwait"
    else
        shift
    fi
    local url="${1:-}"
    local expected_regex="${2:-}"
    local args="${*:3}"
    local retry_interval="${RETRY_INTERVAL:-1}"
    if [ -z "$url" ]; then
        echo "$FUNCNAME: url \$2 not set" >&2
        exit 1
    elif [ -z "$expected_regex" ]; then
        echo "$FUNCNAME: expected content \$3 not set" >&2
        exit 1
    fi
    if ! [[ "$retry_interval" =~ ^[[:digit:]]+$ ]]; then
        echo "$FUNCNAME: invalid non-numeric \$RETRY_INTERVAL '$retry_interval'" >&2
        exit 1
    fi
    #local max_tries=$(($max_secs / $retry_interval))
    timestamp "waiting up to $max_secs secs at $retry_interval sec intervals for HTTP interface to come up with expected regex content: '$expected_regex'"
    found=0
    #for((i=1; i <= $max_tries; i++)); do
    try_number=0
    # special built-in that increments for script runtime, reset to zero exploit it here
    SECONDS=0
    # bash will interpolate from string for correct numeric comparison and safer to quote vars
    if type -P curl &>/dev/null; then
        while [ "$SECONDS" -lt "$max_secs" ]; do
            ((try_number+=1))
            timestamp "$try_number trying $url"
            #
            # tac reads full content to prevent grep closing stdin from causing this curl error:
            #
            #   curl: (23) Failure writing output to destination
            #
            # ignore tac exit code from breaking the pipefail
            #
            # shellcheck disable=SC2086,SC2119
            if curl -skL --connect-timeout 1 --max-time 5 ${args:-} "$url" | { tac || : ; } | grep -Eq -- "$expected_regex"; then
                timestamp "URL content detected '$expected_regex'"
                found=1
                break
            fi
            sleep "$retry_interval"
        done
        if [ $found -eq 1 ]; then
            timestamp "URL content found after $SECONDS secs"
        else
            timestamp "URL content still not available after '$max_secs' secs, giving up waiting"
            return 1
        fi
    else
        timestamp "WARNING: curl command not found in \$PATH, cannot check url content, skipping content checks, tests may fail due to race conditions on service availability"
        timestamp "sleeping for '$max_secs' secs instead"
        sleep "$max_secs"
    fi
}

retry(){
    local max_secs="${1:-}"
    local max_retries="${MAX_RETRIES:-10}"
    local retry_interval="${RETRY_INTERVAL:-1}"
    shift
    if ! [[ "$max_secs" =~ ^[[:digit:]]+$ ]]; then
        die "ERROR: non-integer '$max_secs' passed to $FUNCNAME() for \$1"
    fi
    if ! [[ "$retry_interval" =~ ^[[:digit:]]+$ ]]; then
        die "$FUNCNAME: invalid non-numeric \$RETRY_INTERVAL '$retry_interval'"
    fi
    local negate=""
    expected_return_code="${ERRCODE:-0}"
    if [ "$1" == '!' ]; then
        negate=1
        shift
    fi
    local cmd=("$@")
    if [ -z "$*" ]; then
        die "ERROR: no command passed to $FUNCNAME() for \$3"
    fi
    #echo "retrying for up to $max_secs secs at $retry_interval sec intervals:"
    try_number=0
    SECONDS=0
    while true; do
        ((try_number+=1))
        #echo -n "try $try_number:  "
        set +e
        "${cmd[@]}"
        returncode=$?
        set -e
        if [ -n "$negate" ]; then
            if [ $returncode != 0 ]; then
                RETRY_INFO_MSG="$(timestamp "Command failed after $SECONDS secs" 2>&1)"
                export RETRY_INFO_MSG
                break
            fi
        elif [ "$returncode" = "$expected_return_code" ]; then
            RETRY_INFO_MSG="$(timestamp "Command succeeded with expected exit code of $expected_return_code after $SECONDS secs" 2>&1)"
            export RETRY_INFO_MSG
            break
        fi
        if [ "$try_number" -gt "$max_retries" ]; then
            timestamp "FAILED: giving up after $max_retries retries"
            return 1
        fi
        if [ "$SECONDS" -gt "$max_secs" ]; then
            timestamp "FAILED: giving up after $max_secs secs"
            return 1
        fi
        if [ -n "${RETRY_EXPONENTIAL_BACKOFF:-}" ]; then
            sleep "$(( retry_interval * (2 ** try_number) ))"
        else
            sleep "$retry_interval"
        fi
    done
}


timeout(){
    if is_mac; then
        gtimeout "$@"
    else
        timeout "$@"
    fi
}


usage(){
    local args=""
    local switches=""
    local description=""
    if [ -n "${usage_args:-}" ]; then
        args="$usage_args"
    fi
    if [ -n "${usage_switches:-}" ]; then
        switches="$usage_switches"
        switches="${switches##[[:space:]]}"
        switches="${switches%%[[:space:]]}"
    fi
    if [ -n "${usage_description:-}" ]; then
        description="$usage_description
"
    fi
    if [ -n "$*" ]; then
        echo "$*" >&2
        echo >&2
    fi
    cat >&2 <<EOF
$description
usage: ${0##*/} $args

$switches
-h --help           Print usage help and exit
EOF
    exit 3
}

min_args(){
    local min="$1"
    shift || :
    if [ $# -lt "$min" ]; then
        usage "error: missing arguments"
    fi
}

max_args(){
    local max="$1"
    shift || :
    if [ $# -gt "$max" ]; then
        usage "error: too many arguments, expected $max, got $#"
    fi
}

num_args(){
    local num="$1"
    shift || :
    min_args "$num" "$@"
    max_args "$num" "$@"
}

help_usage(){
    for arg; do
        case "$arg" in
            -h|-help|--help)  usage
                              ;;
        esac
    done
}

any_opt_usage(){
    for arg; do
        case "$arg" in
            -*)  usage
                 ;;
        esac
    done
}
no_more_opts(){
    any_opt_usage "$@"
}

no_more_args(){
    if [ -n "${1:-}" ]; then
        usage "too many args given:  $*"
    fi
}

no_args(){
    if [ -n "${1:-}" ]; then
        usage "args given where none expected:  $*"
    fi
}

check_env_defined(){
    local env="$1"
    if [ -z "${!env:-}" ]; then
        usage "\$$env not defined"
    fi
}

is_yes(){
    shopt -s nocasematch
    if [[ "$1" =~ ^(y|yes)$ ]]; then
        shopt -u nocasematch
        return 0
    else
        shopt -u nocasematch
        return 1
    fi
}

check_yes(){
    local answer="$1"
    if ! is_yes "$answer"; then
        echo "Aborting..." >&2
        exit 1
    fi
}

is_int(){
    local arg="$1"
    [[ "$arg" =~ ^[[:digit:]]+$ ]]
}

is_float(){
    local arg="$1"
    [[ "$arg" =~ ^[[:digit:]]+(\.[[:digit:]]+)?$ ]]
}

is_bool(){
    local arg="$1"
    # intentionally not making this case insensitive in case APIs are touchy about this
    # calling script can set case matching insensitivity if needed
    [[ "$arg" =~ ^true|false$ ]]
}

# [[ regex
is_regex(){
    local regex="$1"
    # right side must not be quoted in order to be properly interpreted as regex
    [[ "$regex" =~ $regex ]]
}

is_port(){
    local port="$1"
    if ! is_int "$port"; then
        return 1
    elif [ "$port" -lt 1 ]; then
        return 1
    elif [ "$port" -gt 65535 ]; then
        return 1
    fi
}

is_url(){
    local arg="$1"
    [[ "$arg" =~ ^$url_regex$ ]]
}

exponential(){
    local int="$1"
    local max="${2:-}"
    if ! is_int "$int"; then
        echo "ERROR: non-integer passed as first arg to exponential() function!" >&2
        return 1
    fi
    if [ -n "$max" ]; then
        if ! is_int "$max"; then
            echo "ERROR: non-integer passed as second arg to exponential() function!" >&2
            return 1
        fi
        if [ "$int" -ge "$max" ]; then
            echo "$max"
            return
        fi
    fi
    local result
    result="$((int * 2))"
    if [ -n "$max" ]; then
        if [ "$result" -gt "$max" ]; then
            result="$max"
        fi
    fi
    echo "$result"
}

parse_export_key_value(){
    local env_var="$1"
    env_var="${env_var%%#*}"
    env_var="${env_var##[[:space:]]}"
    env_var="${env_var##export}"
    env_var="${env_var##[[:space:]]}"
    env_var="${env_var%%[[:space:]]}"
    # when using this in kubectl_kv_to_secret.sh we may want 'some-thing=ENV_VAR'
    # to be able to name the Kubernetes secret key, eg. buildkite-agent-token="$BUILDKITE_AGENT_TOKEN"
    #if ! [[ "$env_var" =~ ^[[:alpha:]][[:alnum:]_]+=.+$ ]]; then
    #    die "invalid environment key=value argument given: $env_var"
    #fi
    # shellcheck disable=SC2034
    key="${env_var%%=*}"
    # shellcheck disable=SC2034
    value="${env_var#*=}"
}

# ============================================================================ #
#                                   JSON utils
# ============================================================================ #

# extremely poor performance on large 3MB json string from https://updates.jenkins.io/current/update-center.actual.json
# seems to hang, not sure why yet, avoid and use a simpler test in that case
is_blank(){
    local arg="${*:-}"
    arg="${arg##[[:space:]]}"
    arg="${arg%%[[:space:]]}"
    [ -z "$arg" ]
    # or
    #[[ "$arg" =~ ^[[:blank:]]*$ ]]
}

not_blank(){
    ! is_blank "$*"
}

is_null(){
    is_blank "${*:-}" || [ "$*" = null ]
}

not_null(){
    ! is_null "$*"
}

has_error_field(){
    # shellcheck disable=SC2181
    if [ $? != 0 ]; then
        return 0
    elif [ "$(jq -r '.error' <<< "$*" || :)" != null ]; then
        return 0
    elif [ "$(jq -r '.errors' <<< "$*" || :)" != null ]; then
        return 0
    elif [ "$(jq -r '.error_description' <<< "$*" || :)" != null ]; then
        return 0
    fi
    return 1
}

die_if_error_field(){
    if [ -z "$*" ]; then
        echo "no json string passed to die_if_error_field()" >&2
        exit 1
    fi
    if has_error_field "$*"; then
        echo "ERROR: $*" >&2
        exit 1
    fi
}

warn_if_error_field(){
    if [ -z "$*" ]; then
        echo "no json string passed to warn_if_error_field()" >&2
        exit 1
    fi
    if has_error_field "$*"; then
        echo "WARNING: $*" >&2
    fi
}

# ==============================

# not wrapping this because in some rare cases we may need to pipe through jq_debug_pipe_dump_slurp instead and this would break (eg. aws_logs_*.sh)
#jq(){
#    jq_debug_pipe_dump |
#    jq "$@"
#}

# pipe debugging filter commands, straight passthrough whether debug mode is enabled or not
jq_debug_pipe_dump(){
    if [ -n "${DEBUG:-}" ]; then
        data="$(cat)"
        jq -r . <<< "$data" >&2 || :
        cat <<< "$data"
    else
        cat  # needed for straight passthrough in non-debug mode
    fi
}

jq_debug_pipe_dump_slurp(){
    if [ -n "${DEBUG:-}" ]; then
        data="$(cat)"
        jq -r -s . <<< "$data" >&2 || :
        call <<< "$data"
    else
        cat  # needed for straight passthrough in non-debug mode
    fi
}

jq_is_empty_list(){
    jq -e 'length == 0' >/dev/null
}
# ==============================

# parse a .dat file's column to CSV - used to generate data for embedding into MermaidJS mmd config in:
#
# git/git_graph_*_mermaidjs.sh
#   and
# github/github_graph_*_mermaidjs.sh
#
parse_file_col_to_csv(){
    local data_file="$1"
    local field="$2"
    awk "{print \$$field}" "$data_file" |
    tr '\n' ',' |
    sed 's/,/, /g; s/, $//'
}

file_modified_in_last_days(){
    local file="$1"
    local days="$2"
    if ! is_int "$days"; then
        die "Non-integer passed as second arg to file_modified_in_last_days()"
    fi
    if ! [ -f "$file" ]; then
        return 1
    elif find "$file" -mtime -"$days" -print | grep -q .; then
        return 0
    else
        local days_ago_in_seconds
        days_ago_in_seconds="$(date -d "$days days ago" '+%s')"
        if is_mac; then
            if [ "$(stat -f '%m' "$file")" -ge "$days_ago_in_seconds" ]; then
                return 0
            else
                return 1
            fi
        elif [ "$(stat -c '%Y' "$file")" -ge "$days_ago_in_seconds" ]; then
            return 0
        else
            return 1
        fi
    fi
}
