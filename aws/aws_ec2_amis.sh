#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2024-11-13 14:42:01 +0400 (Wed, 13 Nov 2024)
#
#  https///github.com/HariSekhon/DevOps-Bash-tools
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
List AWS EC2 AMIs belonging to your account in an easy to read table output

Useful for quickly investigating AMIs

For full details do:

    aws ec2 describe-images --image-ids \"\$AMI_ID\"


$usage_aws_cli_required
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<aws_profile>]"

help_usage "$@"

max_args 1 "$@"

if [ $# -gt 0 ]; then
    aws_profile="$1"
    shift || :
    export AWS_PROFILE="$aws_profile"
fi


# false positive - want single quotes for * to be evaluated within AWS query not shell
# shellcheck disable=SC2016
aws ec2 describe-images \
    --owners self \
    --query 'Images | sort_by(@, &Name)[].{" ID":ImageId, " Name":Name, "CreationDate":CreationDate}' \
    --output table
