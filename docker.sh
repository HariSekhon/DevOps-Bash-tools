#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2016-02-07 22:42:47 +0000 (Sun, 07 Feb 2016)
#
#  https://github.com/harisekhon/bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback
#
#  https://www.linkedin.com/in/harisekhon
#

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir_bash_tools_docker="${srcdir:-}"
srcdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

. "$srcdir/utils.sh"

is_docker_available(){
    #[ -n "${TRAVIS:-}" ] && return 0
    if which docker &>/dev/null; then
        if docker info &>/dev/null; then
            return 0
        fi
    fi
    #echo "Docker not available"
    return 1
}

is_docker_compose_available(){
    #[ -n "${TRAVIS:-}" ] && return 0
    if which docker-compose &>/dev/null; then
        return 0
    fi
    #echo "Docker Compose not available"
    return 1
}

is_docker_container_running(){
    local containers="$(docker ps)"
    if [ -n "${DEBUG:-}" ]; then
        echo "Containers Running:
$containers
"
    fi
    if grep -q "[[:space:]]$1$" <<< "$containers"; then
        return 0
    fi
    return 1
}

external_docker(){
    [ -n "${EXTERNAL_DOCKER:-}" ] && return 0 || return 1
}

startupwait(){
    startupwait="${1:-30}"
    if is_CI; then
        let startupwait*=2
    fi
}

launch_container(){
    local image="${1:-${DOCKER_IMAGE}}"
    local container="${2:-${DOCKER_CONTAINER}}"
    local ports="${@:3}"
    if [ -n "${TRAP:-}" ] || is_CI; then
        trap_container "$container"
    fi
    if external_docker; then
        echo "External Docker detected, skipping container creation..."
        return 0
    else
        [ -n "${DOCKER_HOST:-}" ] && echo "using docker address '$DOCKER_HOST'"
        if ! is_docker_available; then
            echo "WARNING: Docker not found, cannot launch container $container"
            return 1
        fi
        # reuse container it's faster
        #docker rm -f "$container" &>/dev/null
        #sleep 1
        if [[ "$container" = *test* ]]; then
            docker rm -f "$container" &>/dev/null || :
        fi
        if ! is_docker_container_running "$container"; then
            # This is just to quiet down the CI logs from useless download clutter as docker pull/run doesn't have a quiet switch as of 2016 Q3
            if is_CI; then
                # pipe to cat tells docker that stdout is not a tty, switches to non-interactive mode with less output
                { docker pull "$image" || :; } | cat
            fi
            port_mappings=""
            for port in $ports; do
                port_mappings="$port_mappings -p $port:$port"
            done
            echo -n "starting container: "
            # need tty for sudo which Apache startup scripts use while SSH'ing localhost
            # eg. hadoop-start.sh, hbase-start.sh, mesos-start.sh, spark-start.sh, tachyon-start.sh, alluxio-start.sh
            docker run -d -t --name "$container" ${DOCKER_OPTS:-} $port_mappings "$image" ${DOCKER_CMD:-}
            hr
            echo "Running containers:"
            docker ps
            hr
            #echo "waiting $startupwait seconds for container to fully initialize..."
            #sleep $startupwait
        else
            echo "Docker container '$container' already running"
        fi
    fi
    if [ -n "${ENTER:-}" ]; then
        docker exec -ti "$DOCKER_CONTAINER" bash
    fi
}

delete_container(){
    local container="${1:-$DOCKER_CONTAINER}"
    local msg="${2:-}"
    echo
    if [ -z "${NODELETE:-}" ] && ! external_docker; then
        if [ -n "$msg" ]; then
            echo "$msg"
        fi
        echo -n "Deleting container "
        docker rm -f "$container"
        untrap
    fi
}

trap_container(){
    local container="${1:-$DOCKER_CONTAINER}"
    trap 'result=$?; '"delete_container $container 'trapped exit, cleaning up container'"' || : ; exit $result' $TRAP_SIGNALS
}

# restore original srcdir
srcdir="$srcdir_bash_tools_docker"
