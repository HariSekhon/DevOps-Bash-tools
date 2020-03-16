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

# ============================================================================ #
#                        M a c  /  L i n u x   A g e n t
# ============================================================================ #

buildkite_tags="os=linux"

export PATH="$PATH:$HOME/.buildkite-agent/bin"

if type -P buildkite-agent &>/dev/null; then
    if [ -z "${BUILDKITE_DOCKER:-}" ]; then
        uname_s="$(uname -s)"
        if [ "$uname_s" = Darwin ]; then
            buildkite_tags="os=mac"
        elif [ "$uname_s" = Linux ]; then
            buildkite_tags="os=linux"
            distro="$(awk -F= '/^ID=/{print $2}' /etc/*release)"
            distro="${distro//\"/}"
            version="$(awk -F= '/^VERSION_ID=/{print $2}' /etc/*release | grep -Eom 1 '[[:digit:]]+' | head -n 1)"
            buildkite_tags+=",distro=$distro,version=$version"
        else
            buildkite_tags="os=unknown"
        fi
        exec buildkite-agent start --tags "$buildkite_tags"
    fi
fi

# falls through to Docker agent

# ============================================================================ #
#                                  D o c k e r
# ============================================================================ #

# only necessary for Docker, installed agent will have config file containing this token from setup/install_buildkite.sh
if [ -z "${BUILDKITE_AGENT_TOKEN:-}" ]; then
    echo "BUILDKITE_AGENT_TOKEN environment variable not defined"
    exit 1
fi

# latest, alpine, centos, ubuntu, stable, stable-latest, stable-ubuntu etc - see dockerhub_show_tags.py from adjacent DevOps Python tools repo
docker_tag="${BUILDKITE_DOCKER_TAG:-latest}"
if [ -n "${BIG:-}" ] && [ -z "${BUILDKITE_DOCKER_TAG:-}" ]; then
    docker_tag="ubuntu"
fi

if [ "$docker_tag" = "latest" ]; then
    buildkite_tags+=",distro=alpine"
elif [[ "$docker_tag" =~ alpine|centos|ubuntu ]]; then
    buildkite_tags+=",distro=${docker_tag#stable-}"
fi

opts=""
# for debugging so we can docker exec in to machine and build from cwd
if [ -n "${DEBUG:-}" ]; then
    opts="-v $PWD:/pwd"
fi

# want splitting
# shellcheck disable=SC2086
exec docker run $opts -e BUILDKITE_AGENT_TOKEN="$BUILDKITE_AGENT_TOKEN" buildkite/agent:"$docker_tag" start --tags "$buildkite_tags" "$@"
