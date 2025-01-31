#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2025-01-31 16:26:34 +0700 (Fri, 31 Jan 2025)
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
Polls an AWS EC2 instance and waits for it to finish initializing to a ready state

Used by adjacent script aws_eks_create_custom_ami.sh

Get the AWS EC2 Instance ID from the output of the 'aws ec2 run-instances' command - see above script

Timeout secs defaults to 300 if not specified
Check interval defaults to 5 seconds if not specified


$usage_aws_cli_required
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<instance_id> [<timeout_secs> <check_interval>]"

help_usage "$@"

min_args 1 "$@"

instance_id="$1"

timeout_secs="${2:-300}"

check_interval_secs="${3:-5}"

aws_validate_instance_id "$instance_id"

if ! is_int "$timeout_secs"; then
	die "Invalid Timeout Secs, must be an integer: $timeout_secs"
fi

if ! is_int "$check_interval_secs"; then
	die "Invalid Check Interval Secs, must be an integer: $check_interval_secs"
fi

if [ "$timeout_secs" -lt 1 ]; then
	die "Invalid Timeout Secs cannot be less than 1: $timeout_secs"
fi

if [ "$check_interval_secs" -lt 1 ]; then
	die "Invalid Check Interval Secs cannot be less than 1: $check_interval_secs"
fi

timestamp "Waiting for AWS EC2 instance to become ready: $instance_id"
timestamp "Check interval: $check_interval_secs secs"
timestamp "Timeout max: $timeout_secs secs"

SECONDS=0

timestamp "Checking EC2 instance status..."
while true; do
    if [ "$SECONDS" -gt "$timeout_secs" ]; then
        die "ERROR: Timed out waiting $timeout_secs for instance to become ready"
    fi
    instance_checks="$(
        aws ec2 describe-instance-status \
            --instance-ids "$instance_id" \
            --query "InstanceStatuses[0].InstanceStatus.Status" \
            --output text
    )"
    if [ "$instance_checks" = "ok" ]; then
        system_checks="$(
            aws ec2 describe-instance-status \
                --instance-ids "$instance_id" \
                --query "InstanceStatuses[0].SystemStatus.Status" \
                --output text
        )"

        if [ "$instance_checks" = "ok" ] &&
           [ "$system_checks" = "ok" ]; then
            timestamp "EC2 instance $instance_id is ready"
            break
        fi
    fi
    timestamp "AWS EC2 instance still initializing..."
    sleep "$check_interval_secs"
done
