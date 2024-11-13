#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2024-08-29 02:40:31 +0200 (Thu, 29 Aug 2024)
#
#  https://github.com/HariSekhon
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
List EC2 EBS volumes that are not attached to any instance

Ouptut:

<volume_id>  <size>  <availability_zones>  <volume_type>  <state>  <name_tag>, <environment_tag>


$usage_aws_cli_required
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args=""

help_usage "$@"

no_args "$@"

timestamp "Getting EC2 EBS volumes not attached to instances"
echo >&2
# Volumes[*] should not be shell interpreted
# shellcheck disable=SC2016
aws ec2 describe-volumes \
    --filters 'Name=status,Values=available' \
    --query 'Volumes[*].{
        "  VolumeID": VolumeId,
        "  VolumeType": VolumeType,
        " Size": Size,
        " State": State,
        AvailabilityZone: AvailabilityZone,
        Name: Tags[?Key=="Name"].Value | [0],
        Environment: Tags[?Key=="Environment"].Value | [0],
        CreateTime: CreateTime
    }' \
    --output table
