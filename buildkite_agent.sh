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

# Mac / Linux
#buildkite-agent start

# Docker
tag="latest"
#tag="alpine"
#tag="centos"
if [ -n "${BIG:-}" ]; then
    tag="ubuntu"
fi

opts=""
if [ -n "${DEBUG:-}" ]; then
    opts="-v $PWD:/pwd"
fi

# want splitting
# shellcheck disable=SC2086
docker run $opts -e BUILDKITE_AGENT_TOKEN="$BUILDKITE_AGENT_TOKEN" buildkite/agent:"$tag"
