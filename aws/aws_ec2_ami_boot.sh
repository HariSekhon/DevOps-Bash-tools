#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2025-01-31 16:05:24 +0700 (Fri, 31 Jan 2025)
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
Boots an EC2 instance from a given AMI for manual debugging

Useful for interactive debugging when creating AMIs

- checks if there is already an EC2 running instance tagged with your name and AMI ID
  - if yes, reuses it
  - if not, boots an EC2 instance from the AMI with the given security group, subnet id and SSH key-name given so you can SSH to its ec2-user
- waits for the EC2 instance to boot
- waits for the EC2 instance to pass its instance and system checks
- determines the public or private IP address and outputs it to stdout for use in other scripts

It's up to you to Terminate the instance as you may want to leave it running and then create an AMI from it when you've finished testing using this script:

    aws_ec2_ami_create_from_instance.sh

You may want to run this adjacent wrapper script to drop you straight into an SSH prompt:

    aws_ec2_ami_boot_ssh.sh


See Also:

    https://github.com/HariSekhon/Packer


$usage_aws_cli_required
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<ami_id> <instance_type> <security_group> <subnet_id> <ssh-key-name> [<instance_profile>]"

help_usage "$@"

min_args 5 "$@"
max_args 6 "$@"

ami_id="$1"
instance_type="$2"
security_group="$3"
subnet_id="$4"
ssh_key_name="$5"
instance_profile="${6:-}"

aws_validate_security_group_id "$security_group"

aws_validate_subnet_id "$subnet_id"

if ! is_blank "$instance_profile"; then
    if ! [[ "$instance_profile" =~ ^[A-Za-z0-9+=,.@_-]+$ ]]; then
        die "Invalid Instance Profile name: $instance_profile"
    fi
fi

instance_launched=0

user="${USER:-$(whoami)}"

if is_blank "$user"; then
    die "Failed to determine username to tag the EC2 instance with"
fi

for((i=1; i <= 100 ; i++)); do
    instance_name="$user-$ami_id"

    timestamp "Checking if EC2 instance of AMI already exists: $instance_name"
    instance_id="$(
        aws ec2 describe-instances \
            --filters "Name=tag:Name,Values=$instance_name" \
            --query "Reservations[0].Instances[0].InstanceId" \
            --output text
    )"

    if [ "$instance_id" != "None" ]; then
        timestamp "Checking the instance state isn't terminated or shutting down"
        instance_state="$(
            aws ec2 describe-instances \
                --instance-ids "$instance_id" \
                --query "Reservations[0].Instances[0].State.Name" \
                --output text
        )"
        if grep -qi -e terminated -e shutting-down <<< "$instance_state"; then
            timestamp "This instance is already terminated / shutting down, will try a new instance name"
            echo >&2
            continue
        fi
    fi

    if is_blank "$instance_id" || [ "$instance_id" = "None" ]; then
        timestamp "Launching EC2 instance: $instance_name"
        instance_id="$(
            aws ec2 run-instances \
                --image-id "$ami_id" \
                --count 1 \
                --instance-type "$instance_type" \
                --key-name "$ssh_key_name" \
                --security-group-ids "$security_group" \
                --subnet-id "$subnet_id" \
                --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$instance_name}]" \
                --query "Instances[0].InstanceId" \
                --output text
        )"
        timestamp "Launched instance: $instance_id"
    fi
    instance_launched=1
    break
done

if [ "$instance_launched" != 1 ]; then
    die "ERROR: Failed to launch instance"
fi

echo >&2

timestamp "Waiting for instance to be running..."
aws ec2 wait instance-running --instance-ids "$instance_id"
timestamp "Instance is running"

echo >&2

get_instance_profile(){
    local instance_id="$1"
    aws ec2 describe-instances \
        --instance-ids "$instance_id" \
        --query "Reservations[0].Instances[0].IamInstanceProfile.Arn" \
        --output text |
    sed 's|.*/||'
}

if ! is_blank "$instance_profile"; then
    instance_profile_attached=0
    if [ "$(get_instance_profile "$instance_id")" = "$instance_profile" ]; then
        instance_profile_attached=1
    else
        timestamp "Attaching instance profile: $instance_profile"
        aws ec2 associate-iam-instance-profile \
                --instance-id "$instance_id" \
                --iam-instance-profile Name="$instance_profile"
        echo >&2
        timestamp "Waiting for profile to fully attach..."

        instance_profile_attached=0

        for((i=1; i <= 100 ; i++)); do
            current_instance_profile="$(get_instance_profile "$instance_id")"
            if [ "$current_instance_profile" = "None" ]; then
                timestamp "No instance profile associated yet..."
            elif [ "$current_instance_profile" = "$instance_profile" ]; then
                timestamp "Instance profile attached"
                instance_profile_attached=1
                break
            else
                timestamp "Waiting for instance profile to attach..."
            fi

            sleep 3
        done
    fi
    if [ "$instance_profile_attached" != 1 ]; then
        die "Instance profile failed to attach, gave up waiting"
    fi
fi

"$srcdir/aws_ec2_wait_for_instance_ready.sh" "$instance_id"

timestamp "EC2 instance running: $instance_name"
echo "$instance_id"
