#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2016-02-07 22:42:47 +0000 (Sun, 07 Feb 2016)
#
#  https://github.com/harisekhon
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback
#
#  https://www.linkedin.com/in/harisekhon
#

[ -n "${DEBUG:-}" ] && set -x

is_docker_available(){
    #[ -n "${TRAVIS:-}" ] && return 0
    if which docker &>/dev/null; then
        if docker ps &>/dev/null; then
            return 0
        fi
    fi
    echo "Docker not available"
    return 1
}
