#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#  args: google-containers/busybox
#  args: gcr.io/google-containers/busybox
#
#  Author: Hari Sekhon
#  Date: 2020-12-14 12:13:34 +0000 (Mon, 14 Dec 2020)
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
Lists old tags for a given GCR image > \$days old

The \$days threshold defaults to (365 * 2) ie. 2 years old

You can grep and pipe this output to

    | xargs gcloud container images delete -q --force-delete-tags

to clean out old CI image builds to save GCS storage costs on old CI images you no longer use


See Also:

    gcr_tags_timestamps.sh - lists tags and timestamps - useful for comparing with the output from this script

    gcr_*.sh - scripts for Google Container Registry

    aws_ecr_*.sh - scripts for AWS Elastic Container Registry


Requires GCloud SDK to be installed and configured
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<image> [<days_threshold>]"

help_usage "$@"

min_args 1 "$@"
max_args 2 "$@"

image="$1"

if ! [[ "$image" =~ gcr\.io ]]; then
    image="gcr.io/$image"
fi

# $gcr_image_regex is defined in lib/gcp.sh
# shellcheck disable=SC2154
if ! [[ "$image" =~ ^$gcr_image_regex$ ]]; then
    usage "unrecognized gcr image name - should be in a format matching this regex: ^$gcr_image_regex$"
fi


# 2 years old images by default
days_threshold="${2:-$((365 * 2))}"

date_threshold="$(date --date="$days_threshold days ago")"

gcloud container images list-tags "$image" \
                                  --limit 999999 \
                                  --sort-by=TIMESTAMP \
                                  --filter="timestamp.datetime < '$date_threshold'" \
                                  --format=json |
jq -r "map(\"$image\" + \":\" + .tags[]) | .[]"
