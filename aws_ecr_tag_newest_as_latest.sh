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
Finds the newest build of a given AWS ECR docker image by creation date and tags it as 'latest'

Does this via metadata API calls to avoid network transfer from any docker pull / docker push

If an AWS ECR image has multiple tags, will take the longest tag which is assumed to be the most specific and
therefore most likely to avoid collisions and race conditions of other tag updates happening concurrently


$usage_aws_cli_required


Similar scripts:

    aws_ecr_*.sh - scripts for AWS Elastic Container Registry

    gcr_*.sh - scripts for Google Container Registry
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<image> [<aws_cli_options>]"

help_usage "$@"

min_args 1 "$@"

image="$1"
shift || :

tags="$("$srcdir/aws_ecr_newest_image_tags.sh" "$image" "$@")"

if [ -z "$tags" ]; then
    die "No tags were found for image '$image'... does it exist in ECR?"
fi

longest_tag="$(awk '{print length, $0}' <<< "$tags" |
               sort -nr |
               head -n 1 |
               awk '{print $2}')"

"$srcdir/aws_ecr_tag_latest.sh" "$image:$longest_tag" "$@"
