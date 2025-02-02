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
Returns an EC2 AMI ID from name

Adds additional safety checks:

- verifies no more than one AMI ID is returned
- does a reverse lookup on the AMI ID to verify the name
- if an AMI ID is passed, returns it as is for convenience

Investigate AMI names and IDs quickly using adjacent script:

    aws_ec2_amis.sh


$usage_aws_cli_required
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<ami_name>]"

help_usage "$@"

num_args 1 "$@"

ami_name="$1"

if is_ami_id "$ami_name"; then
    log "Given AMI name is already an AWS AMI ID, outputs as is: $ami_name"
    echo "$ami_name"
    exit 0
fi

log "Determining EC2 AMI ID for name '$ami_name'"

ami_id="$(
    aws ec2 describe-images \
        --owners self \
        --filters "Name=name,Values=$ami_name" \
        --query 'Images[*].ImageId' \
        --output text
)"

if is_blank "$ami_id"; then
    die "No EC2 AMI found with name '$ami_name'"
fi

if [ "$(awk '{print NF}' <<< "$ami_id")" -gt 1 ]; then
    cat >&2 <<EOF
More than 1 AMI ID returned, aborting for safety!"

AMI IDs found:

$ami_id
EOF
    exit 1
fi

if ! is_ami_id "$ami_id"; then
    die "Invalid AMI ID returned, failed regex validation: $ami_id"
fi

log "Determined EC2 AMI ID for name '$ami_name' to be '$ami_id'"

log "Doing reverse lookup on AMI ID for safety"

# want * to remain in AWS query rather than evaluated in shell
# shellcheck disable=SC2016
returned_name="$(
    aws ec2 describe-images \
        --image-ids "$ami_id" \
        --query 'Images[0].Name' \
        --output text
)"

if [ "$returned_name" != "$ami_name" ]; then
    die "ERROR: reverse lookup of AMI ID '$ami_id' returned '$returned_name' instead of expected '$ami_name' - aborting for safety"
fi

log "Reverse lookup on AMI ID for safety correctly returned name '$returned_name'"


log "We definitely have the right AMI ID, outputting AMI ID: $ami_id"

echo "$ami_id"
