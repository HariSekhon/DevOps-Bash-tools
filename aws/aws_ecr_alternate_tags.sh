#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#  args: haritest:1.0 stable
#
#  Author: Hari Sekhon
#  Date: 2021-12-10 11:30:51 +0000 (Fri, 10 Dec 2021)
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
Lists all alternative tags for the given specific ECR docker image:tag

If a container has multiple tags (eg. latest, v1, hashref), you can supply '<image>:latest' to see which version has been tagged to 'latest'

Each tag for the given <image>:<tag> is output on a separate line for easy further piping and filtering, including the originally supplied tag

If no tag is given, assumes 'latest'

If the image isn't found in GCR, will return nothing and no error code since this is the default GCloud SDK behaviour

$usage_aws_cli_jq_required


Similar scripts:

    aws_ecr_*.sh - scripts for AWS Elastic Container Registry

    gcr_*.sh - scripts for Google Container Registry
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<image>:<tag> [<aws_cli_options>]"

help_usage "$@"

min_args 1 "$@"

image_tag="$1"
shift || :

image="${image_tag%%:*}"
tag="${image_tag##*:}"
if [ -z "$tag" ] || [ "$tag" = "$image" ]; then
    tag="latest"
fi

aws ecr describe-images --repository-name "$image" --image-ids "imageTag=$tag" "$@" |
jq -r '.imageDetails[].imageTags[]' |
sort
