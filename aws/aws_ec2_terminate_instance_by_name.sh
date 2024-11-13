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

Investigate instance names quickly using adjacent script aws_ec2_instance_states.sh


$usage_aws_cli_required
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<instance_name>"

help_usage "$@"

num_args 1 "$@"

instance_name="$1"

instance_id="$(VERBOSE=1 "$srcdir/aws_ec2_instance_name_to_id.sh" "$instance_name")"

if ! is_instance_id "$instance_id"; then
    die "Invalid Instance ID returned, failed regex validation: $instance_id"
fi

echo

timestamp "Checking instance state"
instance_state="$(
    aws ec2 describe-instances --instance-ids "$instance_id" --query 'Reservations[*].Instances[*].State.Name' --output text
)"
if [ "$instance_state" = "terminated" ]; then
    timestamp "Instance '$instance_name' with id '$instance_id' is already terminated"
    exit 0
elif [ "$instance_state" != "running" ]; then
    die "Instance state '$instance_state' was not expected - is not 'terminated' or 'running' - aborting for safety"
fi
echo >&2

read -r -p "Do you want to terminate instance '$instance_name' with id '$instance_id'? (y/N) " answer
check_yes "$answer"
aws ec2 terminate-instances --instance-ids "$instance_id"
