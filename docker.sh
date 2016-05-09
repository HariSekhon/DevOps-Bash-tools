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

srcdir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

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

launch_container(){
    local image="${1:-${DOCKER_IMAGE}}"
    local container="${2:-${DOCKER_CONTAINER}}"
    local ports="${@:3}"
    local startupwait2="${startupwait:-30}"
    is_travis && let startupwait2*=2
    if external_docker; then
        echo "External Docker detected, skipping container creation..."
        return 0
    else
        echo "using docker address '$DOCKER_HOST'"
        if ! is_docker_available; then
            echo "WARNING: Docker not found, cannot launch container $container"
            return 1
        fi
        # reuse container it's faster
        #docker rm -f "$container" &>/dev/null
        #sleep 1
        if ! is_docker_container_running "$container"; then
            [ -n "${DELETE_IF_RUNNING:-}" ] && docker rm -f "$container" &>/dev/null || :
            port_mappings=""
            for port in $ports; do
                port_mappings="$port_mappings -p $port:$port"
            done
            echo -n "starting container: "
            # need tty for sudo which hbase-start.sh local uses while ssh'ing localhost
            docker run -d -t --name "$container" $port_mappings $image
            hr
            echo "Running containers:"
            docker ps
            hr
            echo "waiting $startupwait2 seconds for container to fully initialize..."
            sleep $startupwait2
        else
            echo "Docker container '$container' already running"
        fi
    fi
}

delete_container(){
    local container="${1:-$DOCKER_CONTAINER}"
    echo
    if [ -z "${NODELETE:-}" ] && ! external_docker; then
        echo -n "Deleting container "
        docker rm -f "$container"
    fi
}
