#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-09-15 14:52:47 +0100 (Tue, 15 Sep 2020)
#
#  https://github.com/HariSekhon/bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/HariSekhon
#

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck disable=SC1090
. "$srcdir/lib/utils.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Tags a given Docker image:tag in Google Cloud Registry as 'latest' without pulling and pushing the docker image

Requires GCloud SDK to be installed and configured
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<gcr.io>/<project_id>/<image>:<tag>"

help_usage "$@"

num_args 1 "$@"

image_tag="$1"

regex='^([^\.]+\.)?gcr\.io/[^/]+/[^:]+:.+$'
if ! [[ "$image_tag" =~ $regex ]]; then
    usage "unrecognized GCR image:tag name - should be in a format matching this regex: $regex"
fi

docker_image="${image_tag%%:*}"
tag="${image_tag##*:}"

echo "tagging docker image $docker_image:$tag as 'latest'"
# --quiet otherwise prompts Y/n which would hang build
gcloud container images add-tag --quiet "$docker_image:$tag" "$docker_image:latest"
