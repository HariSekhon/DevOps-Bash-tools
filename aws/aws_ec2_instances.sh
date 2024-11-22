#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2024-08-27 11:28:20 +0200 (Tue, 27 Aug 2024)
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
List AWS EC2 instances, their DNS names and States in an easy to read table output

Useful for quickly investigating running instances and comparing to configured FQDN addresses in referencing software

See also:

    aws_ec2_info.sh - gives similar info but also resolves AMI names and adds an architecture column
    aws_ec2_info_csv.sh - same as above but in quoted CSV format

$usage_aws_cli_required
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args=""

help_usage "$@"

num_args 0 "$@"

# false positive - want single quotes for * to be evaluated within AWS query not shell
# shellcheck disable=SC2016
#
# prefixing the column headings with spaces forces them to come first so that we can get the State field
# in the middle instead of end since AWS CLI seems to sort the columns lexically
aws ec2 describe-instances \
    --query 'Reservations[*].Instances[*].{
                "  Name": Tags[?Key==`Name`].Value | [0],
                "  ID": InstanceId,
                "  State": State.Name,
                " InstanceType": InstanceType,
                "Public DNS": publicDnsName,
                "Private DNS": PrivateDnsName
            }' \
    --output table
