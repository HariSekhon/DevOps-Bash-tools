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

# Triggers BuildKite job for repo given as argument

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x

if [ -z "${BUILDKITE_TOKEN:-}" ]; then
    echo "BUILDKITE_TOKEN environment variable not defined"
fi

usage(){
    echo "usage: ${0##*/} repo"
    exit 3
}

# remember to set this eg. BUILDKITE_USER="hari-sekhon"
buildkite_user="${BUILDKITE_USER:-${GITHUB_USER:-${GIT_USER:-${USER:-}}}}"

repo="${1:-${BUILDKITE_REPO:-${REPO:-}}}"

if [ -z "$buildkite_user" ]; then
    usage "\$BUILDKITE_USER not defined"
fi

if [ -z "$repo" ]; then
    usage "\$BUILDKITE_REPO not defined"
fi

curl \
    "https://api.buildkite.com/v2/organizations/$buildkite_user/pipelines/$repo/builds" \
    -H "Authorization: Bearer $BUILDKITE_TOKEN" \
    -X "POST" \
    -F "commit=${BUILDKITE_COMMIT:-HEAD}" \
    -F "branch=${BUILDKITE_BRANCH:-master}" \
    -F "message=triggered by Hari Sekhon ${0##*/} script"
