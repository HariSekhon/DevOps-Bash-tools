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
Clones an AWS EC2 instance by creating an AMI from the original and then booting a new instance from the AMI
with the same settings as the original instance

Useful to testing risky things on a separate EC2 instance, such as Server Administrator recovery of Tableau

Does not reboot the running EC2 instance for safety by default, which means a non-clean filesystem copy
unless you shut it down first.

To enforce a reboot of the EC2 instance (be careful in production!) you must set the environment variable:

    export AWS_EC2_REBOOT_INSTANCE=true

Uses adjacent scripts:

    aws_ec2_create_ami_from_instance.sh

    aws_ec2_instance_name_to_id.sh

Investigate instance names quickly using adjacent script aws_ec2_instances.sh


$usage_aws_cli_required
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<instance_name> <new_instance_name>"

help_usage "$@"

num_args 2 "$@"

instance_name="$1"

new_instance_name="$2"

ami_name="instance-$instance_name-$(date '+%F_%H%M%S')"

# this script has been updated to wait for the AMI state to become available
ami_id="$("$srcdir/aws_ec2_create_ami_from_instance.sh" "$instance_name" "$ami_name")"
echo >&2

if ! is_ami_id "$ami_id"; then
    die "Invalid AMI ID returned, failed regex validation: $ami_id"
fi

timestamp "Determining instance ID of original EC2 instance '$instance_name'"
instance_id="$("$srcdir/aws_ec2_instance_name_to_id.sh" "$instance_name")"
if ! is_instance_id "$instance_id"; then
    die "Invalid Instance ID returned, failed regex validation: $instance_id"
fi
timestamp "Determined instance ID to be: $instance_id"
echo >&2

timestamp "Determining instance type of original instance"
instance_type="$(
    aws ec2 describe-instances \
        --instance-ids "$instance_id" \
        --query 'Reservations[*].Instances[*].InstanceType' \
        --output text
)"
if is_blank "$instance_type"; then
    die "Failed to determine instance type"
fi
timestamp "Determined instance type to be: $instance_type"
echo >&2

timestamp "Determining subnet ID of original instance"
subnet_id="$(
    aws ec2 describe-instances \
        --instance-ids "$instance_id" \
        --query 'Reservations[*].Instances[*].SubnetId' \
        --output text
)"
if is_blank "$subnet_id"; then
    die "Failed to determine subnet ID"
fi
timestamp "Determined subnet ID to be: $subnet_id"
echo >&2

timestamp "Determining key pair name of original instance"
key_name="$(
    aws ec2 describe-instances \
        --instance-ids "$instance_id" \
        --query 'Reservations[*].Instances[*].KeyName' \
        --output text
)"
if is_blank "$key_name"; then
    die "Failed to determine key name"
fi
timestamp "Determined key pair name to be: $key_name"
echo >&2

timestamp "Determining security group IDs of original instance"
security_group_ids="$(
    aws ec2 describe-instances \
        --instance-ids "$instance_id" \
        --query 'Reservations[*].Instances[*].SecurityGroups[*].GroupId' \
        --output text |
    tr '\n' ',' |
    sed 's/,$//'
)"
if is_blank "$security_group_ids"; then
    die "Failed to determine security group IDs"
fi
timestamp "Determined security group ID to be: $security_group_ids"
echo >&2

timestamp "Launching new EC2 instance from AMI '$ami_name'"
new_instance_id="$(
    aws ec2 run-instances \
        --image-id "$ami_id" \
        --instance-type "$instance_type" \
        --subnet-id "$subnet_id" \
        --key-name "$key_name" \
        --security-group-ids "$security_group_ids" \
        --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$new_instance_name}]" |
    jq -r '.Instances[0].InstanceId'
)"
echo >&2

timestamp "Waiting for new EC2 instance '$new_instance_name' ($new_instance_id) to enter running state"
echo >&2

# special variable that increments - use as a built-in timer
SECONDS=0

while true; do
    state="$(
        aws ec2 describe-instances \
            --instance-ids "$instance_id" \
            --query 'Reservations[*].Instances[*].State.Name' \
            --output text
    )"

    if [ "$state" = "running" ]; then
        timestamp "New instance '$new_instance_name' is now running after $SECONDS seconds"
        break
    elif [ "$SECONDS" -gt 1200 ]; then
        die "Waited for 20 minutes but instance did not enter running state, something is wrong, aborting..."
    fi
    timestamp "Waiting for instance '$new_instance_name' to enter running state. State: $state"
    sleep 10
done

echo "$instance_id"
