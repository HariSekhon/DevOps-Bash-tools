#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#  args: haritest:1.0 stable
#
#  Author: Hari Sekhon
#  Date: 2020-09-28 11:45:38 +0100 (Mon, 28 Sep 2020)
#
#  https://github.com/HariSekhon/bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/HariSekhon
#

# https://docs.aws.amazon.com/AmazonECR/latest/userguide/image-retag.html

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck disable=SC1090
. "$srcdir/lib/aws.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Tags an AWS ECR image with another tag without pulling + pushing the image

If :<tag> isn't given, assumes 'latest'

(this is easier to do on GCP as there is a supported command, hence the reason for this script)


$usage_aws_cli_required


Similar scripts:

    docker_registry_tag_image.sh - for private Docker Registries

    gcr_*.sh - scripts for Google Container Registry
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<image>:<tag> <new_tag>"

help_usage "$@"

min_args 2 "$@"

image_tag="$1"
new_tag="$2"

image="${image_tag%%:*}"
tag="${image_tag##*:}"
if ! [[ "$image_tag" =~ : ]] &&
   [ "$tag" = "$image" ]; then
    tag="latest"
fi

tstamp "getting manifest for image '$image:$tag'"
manifest="$(aws ecr batch-get-image --repository-name "$image" --image-ids "imageTag=$tag" --query 'images[].imageManifest' --output text)"

tstamp "tagging image '$image:$tag' with new tag '$new_tag'"
aws ecr put-image --repository-name "$image" --image-tag "$new_tag" --image-manifest "$manifest"

tstamp "tags for image '$image:$tag' are now:"
aws ecr describe-images --repository-name "$image" |
jq -r '.imageDetails[] | select(.imageTags[] == "latest") | .imageTags[]'
