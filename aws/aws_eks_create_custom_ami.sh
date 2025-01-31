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
Create a custom EKS AMI quickly off the base EKS template and then running a shell script in it
before saving it to a new AMI

- finds the standard EKS AMI for the given version
- checks if there is already an EC2 running instance tagged for this
- boots an EC2 instance from the above AMI with the given security group, subnet id and SSH key-name given so you can SSH to its ec2-user
- waits for the EC2 instance to boot
- waits for the EC2 instance to pass its instance and system checks
- determines the public or private IP address
- scp's the local script to the instance /tmp
- SSH's to execute the script (eg. to install the needed things)
- Assumes ~/.ssh/<ssh-key-name>,pem is present locally to be able to log in to it
- Creates the AMI
- Terminates the EC2 instance

$usage_aws_cli_required
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<custom_ami_name> <eks_version> <instance_type> <security_group> <subnet_id> <ssh-key-name> <script> [<instance_profile>]"

help_usage "$@"

min_args 7 "$@"
max_args 8 "$@"

custom_ami_name="$1"
eks_version="$2"
instance_type="$3"
security_group="$4"
subnet_id="$5"
ssh_key_name="$6"
script="$7"  # on local filesystem because its private
instance_profile="${8:-}"

aws_validate_security_group_id "$security_group"

aws_validate_subnet_id "$subnet_id"

if ! is_blank "$instance_profile"; then
    if ! [[ "$instance_profile" =~ ^[A-Za-z0-9+=,.@_-]+$ ]]; then
        die "Invalid Instance Profile name: $instance_profile"
    fi
fi

timestamp "Getting the latest EKS optimized AMI for $eks_version"
base_ami="$(
    aws ssm get-parameters \
        --names "/aws/service/eks/optimized-ami/$eks_version/amazon-linux-2/recommended/image_id" \
        --query "Parameters[0].Value" --output text
)"

if is_blank "$base_ami"; then
    die "Failed to determine EKS AMI for version $eks_version"
fi
timestamp "Base EKS AMI is: $base_ami"
echo >&2

instance_launched=0

for((i=1; i <= 100 ; i++)); do
    instance_name="EKS-$eks_version-Instance-for-Custom-AMI-$i"

    timestamp "Checking if EC2 instance of EKS Base AMI already exists: $instance_name"
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
        timestamp "Launching EC2 instance of EKS Base AMI: $instance_name"
        instance_id="$(
            aws ec2 run-instances \
                --image-id "$base_ami" \
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
fi

if [ "$instance_profile_attached" != 1 ]; then
    die "Instance profile failed to attach, gave up waiting"
fi

"$srcdir/aws_ec2_wait_for_instance_ready.sh" "$instance_id"

echo >&2

# EC2 instance isn't SSM integrated at this point to send commands
#
#timestamp "Copying custom script to instance via SSM"
#aws ssm send-command \
#    --instance-ids "$instance_id" \
#    --document-name "AWS-RunShellScript" \
#    --comment "Running Custom Install Script" \
#    --parameters "commands=[\"echo '$script' > /tmp/custom-script.sh\", \"chmod +x /tmp/custom-script.sh\"]"
#    #--parameters 'commands=["curl -O '"$script_url"'", "bash ./your-custom-script.sh"]'
#
#timestamp "Running custom install script via SSM"
#command_id="$(
#    aws ssm send-command \
#        --instance-ids "$instance_id" \
#        --document-name "AWS-RunShellScript" \
#        --comment "Running Custom Install Script" \
#        --parameters 'commands=["/tmp/custom-script.sh"]' \
#        --query "Command.CommandId" \
#        --output text
#)"

#timestamp "Waiting for script execution..."
#"$srcdir/aws_ssm_wait_for_command_to_finish.sh" "$command_id"

timestamp "Getting instance public IP"
public_ip="$(
    aws ec2 describe-instances \
        --instance-ids "$instance_id" \
        --query "Reservations[0].Instances[0].PublicIpAddress" \
        --output text
)"

if ! is_blank "$public_ip" &&
   [ "$public_ip" != "None" ]; then
    ip="$public_ip"
    timestamp "Using instance public IP: $ip"
else
    timestamp "No public IP found, getting instance private IP"
    private_ip="$(
        aws ec2 describe-instances \
            --instance-ids "$instance_id" \
            --query "Reservations[0].Instances[0].PrivateIpAddress" \
            --output text
    )"
    ip="$private_ip"
    timestamp "Using instance private IP: $ip"
fi

echo >&2

timestamp "Copying script to instance: $script"

# this is a brand new instance so the SSH host key won't be trusted
scp -i ~/.ssh/"$ssh_key_name.pem" \
    -o StrictHostKeyChecking=no \
    "$script" \
    ec2-user@"$ip":/tmp/
echo >&2

instance_script="/tmp/${script##*/}"

timestamp "Executing script on instance: $instance_script"
ssh -i ~/.ssh/"$ssh_key_name.pem" ec2-user@"$ip" "chmod +x $instance_script && $instance_script"

echo >&2

"$srcdir/aws_ec2_create_ami_from_instance.sh" "$instance_id" "$custom_ami_name"

#timestamp "Creating Custom AMI from running EC2 instance"
#custom_ami_id="$(
#    aws ec2 create-image \
#        --instance-id "$instance_id" \
#        --name "$custom_ami_name" \
#        --no-reboot \
#        --query "ImageId" \
#        --output text
#)"
#timestamp "Custom AMI creation initiated: $custom_ami_id"

echo >&2

timestamp "Terminating temporary EC2 instance: $instance_id"
aws ec2 terminate-instances --instance-ids "$instance_id"
timestamp "Terminated temporary EC2 instance: $instance_id"

timestamp "Waiting for EC2 instance termination"
aws ec2 wait instance-terminated --instance-ids "$instance_id"
timestamp "Instance terminated"
timestamp "Custom EKS AMI creation completed"
