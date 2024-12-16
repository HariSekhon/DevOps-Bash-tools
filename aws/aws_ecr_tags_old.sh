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
Lists old tags for a given AWS ECR image > \$days old

The \$days threshold defaults to (365 * 2) ie. 2 years old

You can grep and pipe this output to

    | xargs -L1 aws_ecr_delete_tag.sh

to clean out old CI image builds to save S3 storage costs on old CI images you no longer use


$usage_aws_cli_jq_required


See Also:

    aws_ecr_tags_timestamps.sh - lists tags and timestamps - useful for comparing with the output from this script

    aws_ecr_*.sh - scripts for AWS Elastic Container Registry

    gcr_*.sh - scripts for Google Container Registry
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<image> [<days_threshold> <aws_cli_options>]"

help_usage "$@"

min_args 1 "$@"

image="$1"

# 2 years old images by default
days_threshold="${2:-$((365 * 2))}"

shift || :
shift || :

date_threshold="$(date '+%FT%T+00:00' --utc --date="$days_threshold days ago")"

aws ecr describe-images --repository-name "$image" "$@" |
jq -r ".imageDetails[] |
       select(.imagePushedAt < \"$date_threshold\") |
       [\"$image\" + \":\" + .imageTags[]] |
       .[]"
