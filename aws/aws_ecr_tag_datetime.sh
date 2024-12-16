#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#  args: haritest:1.0 stable
#
#  Author: Hari Sekhon
#  Date: 2021-12-10 11:53:32 +0000 (Fri, 10 Dec 2021)
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
. "$srcdir/lib/aws.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Tags a given ECR docker image with it's creation Date and Timestamp
without pulling and pushing the docker image

The timestamp is the created time (either uploaded or created by Google Cloud Build)

Tags are in the format:

YYYY-MM-DD
YYYY-MM-DDTHHMMSSZ  (standard ISO UTC time without semi-colons which are invalid in docker tags)

The timestamp will be normalized to UTC


$usage_aws_cli_jq_required


Similar scripts:

    aws_ecr_*.sh - scripts for AWS Elastic Container Registry

    gcr_*.sh - scripts for Google Container Registry
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<image>:<tag> [<aws_cli_options>]"

help_usage "$@"

num_args 1 "$@"

image_tag="$1"
shift || :

if ! [[ "$image_tag" =~ : ]]; then
    image_tag+=":latest"
fi

image="${image_tag%%:*}"
tag="${image_tag##*:}"

if [ -z "$tag" ] ||
   [ "$tag" = "$image" ] ||
   [ "$tag" = "$image_tag" ]; then
    tag="latest"
fi

timestamp="$(aws ecr describe-images --repository-name "$image" --image-ids "imageTag=$tag" "$@" | jq -r '.imageDetails[].imagePushedAt' | sort -r | head -n1)"
if [ -z "$timestamp" ]; then
    echo "Failed to determine timestamp from ECR for image '$image' with tag '$tag'"
    exit 1
fi
if ! [[ "$timestamp" =~ ^[[:digit:]]{4}-[[:digit:]]{2}-[[:digit:]]{2}T[[:digit:]]{2}:[[:digit:]]{2}:[[:digit:]]{2}[+-][[:digit:]]{2}:[[:digit:]]{2}$ ]]; then
    echo "ECR timestamp not in expect YYYY-MM-DDTHH:MM:SS[+-]HH:MM format, API may have changed"
    exit 1
fi

# normalize to UTC
timestamp="$(date --utc --date="$timestamp" '+%FT%H%M%SZ')"

date="${timestamp%T*}"

FORCE=1 "$srcdir/aws_ecr_tag_image.sh" "$image:$tag" "$date" "$@"
FORCE=1 "$srcdir/aws_ecr_tag_image.sh" "$image:$tag" "$timestamp" "$@"
