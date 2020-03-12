#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-03-11 18:02:32 +0000 (Wed, 11 Mar 2020)
#
#  https://github.com/harisekhon/bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/harisekhon
#

# Runs BuildKite Agent
#
# see /usr/local/etc/buildkite-agent/buildkite-agent.cfg for config on Mac

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x

BUILDKITE_AGENT_TOKEN="${1:-${BUILDKITE_AGENT_TOKEN:-${BUILDKITE_TOKEN:-}}}"

if [ -z "${BUILDKITE_AGENT_TOKEN:-}" ]; then
    echo "BUILDKITE_AGENT_TOKEN / BUILDKITE_TOKEN environment variable not defined"
fi

buildkite_tags="os=linux"

export PATH="$PATH:$HOME/.buildkite-agent/bin"

# Mac / Linux
if type -P buildkite-agent &>/dev/null; then
    if [ -z "${BUILDKITE_DOCKER:-}" ]; then
        uname_s="$(uname -s)"
        if [ "$uname_s" = Darwin ]; then
            buildkite_tags="os=mac"
        elif [ "$uname_s" = Linux ]; then
            buildkite_tags="os=linux"
        else
            buildkite_tags="os=unknown"
        fi
        exec buildkite-agent start --tags "$buildkite_tags"
    fi
fi

# Docker
docker_tag="latest"
#docker_tag="alpine"
#docker_tag="centos"
if [ -n "${BIG:-}" ]; then
    docker_tag="ubuntu"
fi

opts=""
# for debugging so we can docker exec in to machine and build from cwd
if [ -n "${DEBUG:-}" ]; then
    opts="-v $PWD:/pwd"
fi

# want splitting
# shellcheck disable=SC2086
docker run $opts -e BUILDKITE_AGENT_TOKEN="$BUILDKITE_AGENT_TOKEN" buildkite/agent:"$docker_tag" start --tags "$buildkite_tags"
