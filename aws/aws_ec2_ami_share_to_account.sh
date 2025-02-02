#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2025-02-03 06:01:48 +0700 (Mon, 03 Feb 2025)
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
Shares an AMI with another AWS account

Useful to build your AMIs in your CI/CD account and then share to your various projects and environment accounts


See also:

    https://github.com/HariSekhon/Packer


For building the AMI in your CI/CD account


$usage_aws_cli_required
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<ami_name_or_id> <aws_account_id>"

help_usage "$@"

num_args 2 "$@"

ami_name_or_id="$1"
aws_account_id="$2"

ami_id="$("$srcdir/aws_ec2_ami_name_to_id.sh" "$ami_name_or_id")"

timestamp "Sharing AMI '$ami_id' with AWS account '$aws_account_id'"

echo

aws ec2 modify-image-attribute \
    --image-id "$ami_id" \
    --launch-permission "Add=[{UserId=$aws_account_id}]"

echo

timestamp "AMI '$ami_id' successfully shared with AWS account '$aws_account_id'"
