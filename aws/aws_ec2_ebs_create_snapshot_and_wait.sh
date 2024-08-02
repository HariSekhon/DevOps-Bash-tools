#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2024-08-02 10:14:03 +0300 (Fri, 02 Aug 2024)
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
Creates a snapshot of a given EBS volume ID and waits for it to complete with exponential backoff

Useful to take before enlarging EBS volumes as a backup in case anything goes wrong

Automatically determines the EC2 instance name and prefixes it to the snapshot description


Use the adjacent script aws_ec2_ebs_volumes.sh to easily get the volume ID


$usage_aws_cli_required
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<ebs_volume_id> <description>"

help_usage "$@"

# enforce giving a 2nd arg for description
num_args 2 "$@"

volume_id="$1"
description="$2"

aws_validate_volume_id "$volume_id"

export MAX_WATCH_SLEEP_SECS=300

export AWS_DEFAULT_OUTPUT=json

timestamp "Finding EC2 instance ID for volume ID '$volume_id'"
instance_id="$(aws ec2 describe-volumes --volume-ids "$volume_id" --query 'Volumes[*].Attachments[*].InstanceId' --output text)"

timestamp "Finding EC2 instance name for instance ID '$instance_id'"
# false positive
# shellcheck disable=SC2016
instance_name="$(aws ec2 describe-instances --instance-ids "$instance_id" --query 'Reservations[*].Instances[*].{InstanceID:InstanceId,Name:Tags[?Key==`Name`].Value|[0]}' --output json | jq -r '.[].[].Name' | head -n 1)"

# automatically prefix the description with the instance name
description="$instance_name: $description"

timestamp "Taking snapshot of volume '$volume_id' on EC2 instance '$instance_name' with description '$description'"
snapshot="$(aws ec2 create-snapshot --volume-id "$volume_id" --description "$description" --output json)"
snapshot_id="$(jq -r '.SnapshotId' <<< "$snapshot")"
echo

get_aws_pending_snapshots(){
    # false positive
    # shellcheck disable=SC2016
    aws ec2 describe-snapshots --snapshot-id "$snapshot_id" --query 'Snapshots[?State==`pending`].[VolumeId,SnapshotId,Description,State,Progress]' --output table
}

# will double this for exponential backoff up to MAX_WATCH_SLEEP_SECS interval
sleep_secs=5

# loop indefinitely until we explicitly break using time check
while : ; do
    if [ "$SECONDS" -gt 7200 ]; then
        die "Timed out waiting 2 hours for EBS snapshot to complete!"
    fi
    if get_aws_pending_snapshots | tee /dev/stderr | grep -Fq "$description"; then
        echo
        timestamp "Snapshot still in pending state, waiting $sleep_secs secs before checking again"
        sleep "$sleep_secs"
        # exponential backoff
        sleep_secs="$(exponential "$sleep_secs" "$MAX_WATCH_SLEEP_SECS")"
        continue
    fi
    break
done

echo
timestamp "Snapshot completed"
