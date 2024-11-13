#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2024-08-27 11:28:25 +0200 (Tue, 27 Aug 2024)
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
Returns an EC2 instance ID from name

Adds additional safety checks:

- verifies no more than one instance ID is returned
- does a reverse lookup on the instance ID to verify the name
- if an instance ID is passed, returns it as is for convenience

Called by adjacent scripts like:

    aws_ec2_create_ami_from_instance.sh

    aws_ec2_terminate_instance_by_name.sh

Investigate instance names and IDs quickly using adjacent script aws_ec2_instance_states.sh


$usage_aws_cli_required
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<instance_name>"

help_usage "$@"

num_args 1 "$@"

instance_name="$1"

if [[ "$instance_name" =~ ^i-[0-9a-f]{8,17}$ ]]; then
    log "Given instance name is already an AWS instance ID, outputs as is: $instance_name"
    echo "$instance_name"
    exit 0
fi

log "Determining EC2 instance ID for name '$instance_name'"

instance_id="$(
    aws ec2 describe-instances \
        --filters "Name=tag:Name,Values=$instance_name" \
        --query "Reservations[*].Instances[*].InstanceId" \
        --output text
)"

if is_blank "$instance_id"; then
    die "No EC2 instance found with name '$instance_name'"
fi

if [ "$(awk '{print NF}' <<< "$instance_id")" -gt 1 ]; then
    cat >&2 <<EOF
More than 1 instance ID returned, aborting for safety!"

Instance ID found:

$instance_id
EOF
    exit 1
fi

if ! is_instance_id "$instance_id"; then
    die "Invalid Instance ID returned, failed regex validation: $instance_id"
fi

log "Determined EC2 instance ID for name '$instance_name' to be '$instance_id'"

log "Doing reverse lookup on instance ID for safety"

# want * to remain in AWS query rather than evaluated in shell
# shellcheck disable=SC2016
returned_name="$(
    aws ec2 describe-instances \
        --instance-ids "$instance_id" \
        --query 'Reservations[*].Instances[*].Tags[?Key==`Name`].Value' \
        --output text
)"

if [ "$returned_name" != "$instance_name" ]; then
    die "ERROR: reverse lookup of instance id '$instance_id' returned '$returned_name' instead of expected '$instance_name' - aborting for safety"
fi

log "Reverse lookup on instance ID for safety correctly returned name '$returned_name'"


log "We definitely have the right instance ID, outputting instance ID: $instance_id"

echo "$instance_id"
