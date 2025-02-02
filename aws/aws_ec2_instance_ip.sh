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
Returns the IP address, public or private, or a given EC2 instance by name or instance id

Used by:

    aws_ec2_ami_boot_ssh.sh


$usage_aws_cli_required
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<instance_name_or_id>"

help_usage "$@"

num_args 1 "$@"

instance="$1"

timestamp "Getting instance public IP for instance: $instance"

instance_id="$("$srcdir/aws_ec2_instance_name_to_id.sh" "$instance")"
timestamp "Instance ID: $instance_id"

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

timestamp "IP address is: $ip"
echo "$ip"
