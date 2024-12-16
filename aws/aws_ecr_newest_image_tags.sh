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
Lists the tags for the given AWS ECR docker image with the newest creation date

(eg. for tagging it as 'latest', see adjacent scripts aws_ecr_tag_latest.sh and aws_ecr_tag_newest_image_as_latest.sh)

When a docker image has multiple tags (eg. v1, latest) then outputs each tag on a separate line for easy further piping and filtering


$usage_aws_cli_jq_required


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

newest_image_timestamp="$(aws ecr describe-images --repository-name "$image" "$@" | jq -r '.imageDetails[].imagePushedAt' | sort -r | head -n1)"

aws ecr describe-images --repository-name "$image" "$@" |
jq -r ".imageDetails[]? | select(.imagePushedAt == \"$newest_image_timestamp\") | .imageTags[]?" |
sort
