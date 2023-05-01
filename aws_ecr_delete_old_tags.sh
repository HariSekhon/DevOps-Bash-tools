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
Deletes tags old than N days for a given AWS ECR image

Useful to clean out old CI image builds to save S3 storage costs on old CI images you no longer use


Prompts with the list of image:tags that it will delete before proceeding for safety.


$usage_aws_cli_required


See Also:

    aws_ecr_tags_old.sh        - used by this script, lists all image:tag older than N days
    aws_ecr_tags_timestamps.sh - lists tags and timestamps - useful for comparing with the output from aws_ecr_tags_old.sh

    aws_ecr_*.sh - scripts for AWS Elastic Container Registry

    gcr_*.sh - scripts for Google Container Registry
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<image> [<days_threshold> <aws_cli_options>]"

help_usage "$@"

min_args 2 "$@"

image="$1"
days="$2"
shift || :
shift || :

image_tags="$("$srcdir/aws_ecr_tags_old.sh" "$image" "$days" "$@")"

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

for image_tag in $image_tags; do
    "$srcdir/aws_ecr_delete_tag.sh" "$image_tag" "$@"
done
