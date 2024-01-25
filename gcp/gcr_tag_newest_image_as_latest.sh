#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#  args: google-containers/busybox
#  args: gcr.io/google-containers/busybox
#
#  Author: Hari Sekhon
#  Date: 2020-09-15 17:17:35 +0100 (Tue, 15 Sep 2020)
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
Finds the newest build of a given GCR docker image by creation date and tags it as 'latest'

Does this via metadata API calls to avoid network transfer from any docker pull / docker push

If a GCR image has multiple tags, will take the longest tag which is assumed to be the most specific and
therefore most likely to avoid collisions and race conditions of other tag updates happening concurrently


Similar scripts:

    aws_ecr_*.sh - scripts for AWS Elastic Container Registry

    gcr_*.sh - scripts for Google Container Registry


Requires GCloud SDK to be installed and configured
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[gcr.io/]<project_id>/<image>"

help_usage "$@"

num_args 1 "$@"

image="$1"

if ! [[ "$image" =~ gcr\.io ]]; then
    image="gcr.io/$image"
fi

# $gcr_image_regex is defined in lib/gcp.sh
# shellcheck disable=SC2154
if ! [[ "$image" =~ ^$gcr_image_regex$ ]]; then
    usage "unrecognized GCR image name - should be in a format matching this regex: ^$gcr_image_regex$"
fi

tags="$("$srcdir/gcr_newest_image_tags.sh" "$@")"

if [ -z "$tags" ]; then
    die "No tags were found for image '$image'... does it exist in GCR?"
fi

longest_tag="$(awk '{print length, $0}' <<< "$tags" |
               sort -nr |
               head -n 1 |
               awk '{print $2}')"

"$srcdir/gcr_tag_latest.sh" "$image:$longest_tag"
