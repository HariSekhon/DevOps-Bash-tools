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
Boots an EC2 instance from a given AMI, determines the public or private IP, and drops you into an SSH shell

Useful for interactive debugging when creating AMIs

- checks if there is already an EC2 running instance tagged with your name and AMI ID
  - if yes, reuses it
  - if not, boots an EC2 instance from the AMI with the given security group, subnet id and SSH key-name given so you can SSH to its ec2-user
- waits for the EC2 instance to boot
- waits for the EC2 instance to pass its instance and system checks
- determines the public or private IP address
- SSH's to the EC2 instance
- Assumes ~/.ssh/<ssh-key-name>,pem is present locally to be able to log in to it

It's up to you to Terminate the instance as you may want to leave it running and then create an AMI from it when you've finished testing using this script:

    aws_ec2_ami_create_from_instance.sh

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

ssh_key_name="$5"

instance_id="$("$srcdir/aws_ec2_ami_boot.sh" "$@")"

ip="$("$srcdir/aws_ec2_instance_ip.sh" "$instance_id")"

timestamp "SSH'ing to EC2 instance"
echo >&2
# this is a brand new instance so the SSH host key won't be trusted
exec ssh \
    -i ~/.ssh/"$ssh_key_name.pem" \
    -o StrictHostKeyChecking=no \
    ec2-user@"$ip"
