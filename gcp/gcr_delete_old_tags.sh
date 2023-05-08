#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#  args: google-containers/busybox $((365 * 4))
#  args: gcr.io/google-containers/busybox $((365 * 4))
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
Deletes tags old than N days for a given GCR image

Useful to clean out old CI image builds to save GCS storage costs on old CI images you no longer use


Prompts with the list of image:tags that it will delete before proceeding for safety.


See Also:

    gcr_tags_old.sh        - used by this script, lists all image:tag older than N days
    gcr_tags_timestamps.sh - lists tags and timestamps - useful for comparing with the output from gcr_tags_old.sh

    gcr_*.sh - scripts for Google Container Registry

    aws_ecr_*.sh - scripts for AWS Elastic Container Registry


Requires GCloud SDK to be installed and configured
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<image> <days_threshold>"

help_usage "$@"

num_args 2 "$@"

image_tags="$("$srcdir/gcr_tags_old.sh" "$@")"

days="$2"

if [ -z "$image_tags" ]; then
    echo "No image:tags older than $days old"
    exit 0
fi

echo
echo "List of image:tags that will be deleted:"
echo
echo "$image_tags"
echo

read -r -p 'Are you sure you want to delete these image:tags listed above? (y/N) ' answer
echo

if [ "$answer" != "y" ]; then
    echo "Aborting..."
    exit 1
fi

xargs gcloud container images delete -q --force-delete-tags <<< "$image_tags"
