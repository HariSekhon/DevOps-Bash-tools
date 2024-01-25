#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#  args: google-containers/busybox:latest
#  args: gcr.io/google-containers/busybox:latest
#
#  Author: Hari Sekhon
#  Date: 2020-09-15 14:52:47 +0100 (Tue, 15 Sep 2020)
#
#  https://github.com/HariSekhon/DevOps-Bash-tools
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

# shellcheck disable=SC1090,SC1091
. "$srcdir/lib/gcp.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Tags a given GCR docker image:tag as 'latest' without pulling and pushing the docker image


Similar scripts:

    aws_ecr_*.sh - scripts for AWS Elastic Container Registry

    gcr_*.sh - scripts for Google Container Registry


Requires GCloud SDK to be installed and configured
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[gcr.io/]<project_id>/<image>:<tag>"

help_usage "$@"

num_args 1 "$@"

image_tag="$1"

if ! [[ "$image_tag" =~ gcr\.io ]]; then
    image_tag="gcr.io/$image_tag"
fi

# $gcr_image_tag_regex is defined in lib/gcp.sh
# shellcheck disable=SC2154
if ! [[ "$image_tag" =~ ^$gcr_image_tag_regex$ ]]; then
    usage "unrecognized GCR image:tag name - should be in a format matching this regex: ^$gcr_image_tag_regex$"
fi

docker_image="${image_tag%%:*}"
tag="${image_tag##*:}"

echo "tagging docker image $docker_image:$tag as 'latest'"
# --quiet otherwise prompts Y/n which would hang build
gcloud container images add-tag --quiet "$docker_image:$tag" "$docker_image:latest"
