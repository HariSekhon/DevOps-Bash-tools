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

# Triggers BuildKite job for a pipeline given as argument

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(dirname "$0")"

usage(){
    if [ -n "$*" ]; then
        echo "$*"
        echo
    fi
    echo "usage: ${0##*/} pipeline"
    exit 3
}

if [ -z "${BUILDKITE_TOKEN:-}" ]; then
    usage "\$$BUILDKITE_TOKEN not defined"
fi

# remember to set this eg. BUILDKITE_ORGANIZATION="hari-sekhon"
BUILDKITE_ORGANIZATION="${BUILDKITE_ORGANIZATION:-${BUILDKITE_ORGANIZATION:-}}"

pipeline="${1:-${BUILDKITE_PIPELINE:-${PIPELINE:-}}}"

if [ -z "$BUILDKITE_ORGANIZATION" ]; then
    usage "\$BUILDKITE_ORGANIZATION not defined"
fi

if [ -z "$pipeline" ]; then
    usage "\$BUILDKITE_PIPELINE not defined and no argument given"
fi

"$srcdir/buildkite_api.sh" "/organizations/$BUILDKITE_ORGANIZATION/pipelines/$pipeline/builds" \
    -X "POST" \
    -F "commit=${BUILDKITE_COMMIT:-HEAD}" \
    -F "branch=${BUILDKITE_BRANCH:-master}" \
    -F "message=triggered by Hari Sekhon ${0##*/} script"
