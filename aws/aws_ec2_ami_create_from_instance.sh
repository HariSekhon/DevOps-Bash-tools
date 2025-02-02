#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2024-11-12 16:42:30 +0400 (Tue, 12 Nov 2024)
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
Creates an AWS EC2 AMI from an EC2 instance and waits for it to become available for use

Outputs the AMI ID to stdout after it becomes available

Useful to testing risky things on another EC2 vm cloned from that AMI

Does not reboot the running EC2 instance for safety by default, which means a non-clean filesystem copy
unless you shut it down first.

To enforce a reboot of the EC2 instance (be careful in production!) you must set the environment variable:

    export AWS_EC2_REBOOT_INSTANCE=true

See it in the list of AMIs afterwards using this command:

    aws ec2 describe-images --owners self --query 'Images[*].{ID:ImageId,Name:Name}' --output table

Check the state of the AMI is finished:

    aws ec2 describe-images --image-ids \"\$AMI_ID\" --output table


Investigate instance names quickly using adjacent script aws_ec2_instances.sh


$usage_aws_cli_jq_required
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<instance_name> <new_ami_name>"

help_usage "$@"

num_args 2 "$@"

instance_name="$1"

ami_name="$2"

instance_id="$(VERBOSE=1 "$srcdir/aws_ec2_instance_name_to_id.sh" "$instance_name")"
if ! is_instance_id "$instance_id"; then
    die "Invalid Instance ID returned, failed regex validation: $instance_id"
fi
echo >&2

no_reboot="--no-reboot"

if [ "${AWS_EC2_REBOOT_INSTANCE:-}" = true ]; then
    timestamp "WARNING: AWS_EC2_REBOOT_INSTANCE environment variable is set to true"
    echo >&2
    read -r -p "Are you sure you want to take down this EC2 instance '$instance_name'? (y/N) " answer
    check_yes "$answer"
    no_reboot=""
    echo >&2
fi

timestamp "Creating AMI '$ami_name' from EC2 instance '$instance_name'"
ami_id="$(
    aws ec2 create-image --instance-id "$instance_id" --name "$ami_name" "$no_reboot" |
    jq -r '.ImageId'
)"
echo >&2

if is_blank "$ami_id" || [ "$ami_id" = null ]; then
    die "Failed to get AMI ID"
elif ! is_ami_id "$ami_id"; then
    die "Invalid AMI ID returned, failed regex validation: $ami_id"
fi

# special variable that increments - use as a built-in timer
SECONDS=0

timestamp "Checking for AMI '$ami_name' to become ready..."
echo >&2

while true; do
    state="$(aws ec2 describe-images --image-ids "$ami_id" | jq -r '.Images[0].State')"
    if [ "$state" = "available" ]; then
        timestamp "AMI '$ami_name' is now available after $SECONDS seconds"
        break
    elif [ "$SECONDS" -gt 1200 ]; then
        die "Waited for 20 minutes without AMI becoming available, something is wrong, aborting..."
    fi
    timestamp "Waiting for AMI '$ami_name' to become ready. State: $state"
    sleep 10
done

echo "$ami_id"
