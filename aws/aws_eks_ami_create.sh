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


Uses adjacent script:

    aws_ec2_ami_boot.sh


You should really use Packer instead, see

    https://github.com/HariSekhon/Packer

But this script is an alternative and allowed me to debug something in a pinch


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

instance_id="$("$srcdir/aws_ec2_ami_boot.sh" "$base_ami" "$instance_type" "$security_group" "$subnet_id" "$ssh_key_name" ${instance_profile:+"$instance_profile"})"

ip="$("$srcdir/aws_ec2_instance_ip.sh" "$instance_id")"

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

"$srcdir/aws_ec2_ami_create_from_instance.sh" "$instance_id" "$custom_ami_name"

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
