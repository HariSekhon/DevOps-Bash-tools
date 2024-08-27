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
Terminate an AWS EC2 instance by name

Investigate instance names quickly using adjacent script aws_ec2_list_instance_states.sh


$usage_aws_cli_required
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<instance_name>"

help_usage "$@"

num_args 1 "$@"

instance_name="$1"

timestamp "Determining EC2 instance ID for name '$instance_name'"
instance_id="$(aws ec2 describe-instances \
    --filters "Name=tag:Name,Values=$instance_name" \
    --query "Reservations[*].Instances[*].InstanceId" \
    --output text)"
if [ "$(awk '{print NF}' <<< "$instance_id")" -gt 1 ]; then
    echo "More than 1 instance ID returned, aborting for safety!"
    echo
    echo "Instance ID found:"
    echo
    echo "$instance_id"
    echo
    exit 1
fi
timestamp "Determined EC2 instance ID for name '$instance_name' to be '$instance_id'"
timestamp "Doing reverse lookup on instance ID for safety"
# want * to remain in AWS query rather than evaluated in shell
# shellcheck disable=SC2016
returned_name="$(aws ec2 describe-instances \
                    --instance-ids "$instance_id" \
                    --query 'Reservations[*].Instances[*].Tags[?Key==`Name`].Value' \
                    --output text)"
if [ "$returned_name" != "$instance_name" ]; then
    die "ERROR: reverse lookup of instance id '$instance_id' returned '$returned_name' instead of expected '$instance_name' - aborting for safety"
fi
timestamp "Reverse lookup on instance ID for safety correctly returned name '$returned_name'"
timestamp "We definitely have the right instance ID"
timestamp "Checking instance state"
instance_state="$(
    aws ec2 describe-instances --instance-ids "$instance_id" --query 'Reservations[*].Instances[*].State.Name' --output text
)"
if [ "$instance_state" = "terminated" ]; then
    timestamp "Instance '$returned_name' with id '$instance_id' is already terminated"
    exit 0
elif [ "$instance_state" != "running" ]; then
    die "Instance state '$instance_state' was not expected - is not 'terminated' or 'running' - aborting for safety"
fi
echo >&2

read -r -p "Do you want to terminate instance '$returned_name' with id '$instance_id'? (y/N) " answer
check_yes "$answer"
aws ec2 terminate-instances --instance-ids "$instance_id"
