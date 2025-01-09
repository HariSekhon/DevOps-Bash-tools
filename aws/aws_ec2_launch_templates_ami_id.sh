#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2025-01-09 20:02:53 +0700 (Thu, 09 Jan 2025)
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
For each Launch Template lists the AMI ID of the latest version

Useful to check EKS upgrades of node groups via Terragrunt have taken effect
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args=""

help_usage "$@"

num_args 0 "$@"

# returns in format:
#
#   ID  NAME
#
launch_templates="$(aws ec2 describe-launch-templates --query "LaunchTemplates[].{Name:LaunchTemplateName,ID:LaunchTemplateId}" --output text)"

while read -r _id name; do
    echo -n "$name "
    aws ec2 describe-launch-template-versions --launch-template-name "$name" |
    jq -r '.LaunchTemplateVersions[0].LaunchTemplateData.ImageId'
done <<< "$launch_templates" # |
#column -t
