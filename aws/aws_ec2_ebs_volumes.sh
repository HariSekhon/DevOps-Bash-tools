#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2024-08-02 09:18:28 +0300 (Fri, 02 Aug 2024)
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
List EC2 instances and their EBS volumes in the current region

Ouptut:

<instance_id>  <instance_name>  <volume_id>  <volume_name>  <volume_size_GB>  <device>  <encrypted>  <delete_on_termination>  <attached/detached>  <attached_time>


$usage_aws_cli_jq_required
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args=""

help_usage "$@"

no_args "$@"

timestamp "Getting EC2 instance list"
while read -r instance_id instance_name; do
    #echo "Instance Name: $instance_name, Instance ID: $instance_id"

    timestamp "Getting volume list for EC2 instance: $instance_name"

    if ! is_instance_id "$instance_id"; then
        die "Invalid Instance ID passed into loop with instance name '$instance_name', failed regex validation: $instance_id"
    fi

    # false positive
    # shellcheck disable=SC2016
    #volume_ids="$(aws ec2 describe-volumes --filters "Name=attachment.instance-id,Values=$instance_id" --query 'Volumes[*].[VolumeId, Tags[?Key==`Name`].Value|[0]]' --output text)"
    volume_info="$(aws ec2 describe-volumes --filters "Name=attachment.instance-id,Values=$instance_id" \
        --query 'Volumes[*].{VolumeID:VolumeId,Name:Tags[?Key==`Name`].Value|[0],Size:Size,Encrypted:Encrypted,Attachments:Attachments[*]}' --output json | jq -c '.[]')"

    while read -r volume; do
        volume_id="$(jq   -r '.VolumeID'  <<< "$volume")"
        volume_name="$(jq -r '.Name'      <<< "$volume" | grep '.' || echo "N/A")"
        volume_size="$(jq -r '.Size'      <<< "$volume")"
        encrypted="$(jq   -r '.Encrypted' <<< "$volume")"

        while read -r attachment; do
            device="$(jq                -r '.Device'              <<< "$attachment")"
            status="$(jq                -r '.State'               <<< "$attachment")"
            attach_time="$(jq           -r '.AttachTime'          <<< "$attachment" | grep '.' || echo "N/A")"
            delete_on_termination="$(jq -r '.DeleteOnTermination' <<< "$attachment")"

            echo "$instance_id $instance_name $volume_id $volume_name ${volume_size}GB $device $encrypted $delete_on_termination $status $attach_time"
        done < <(jq -c '.Attachments[]' <<< "$volume")
    done  <<< "$volume_info"
done < <(
    # false positive
    # shellcheck disable=SC2016
    aws ec2 describe-instances --query 'Reservations[*].Instances[*].{InstanceID:InstanceId,Name:Tags[?Key==`Name`].Value|[0]}' --output text
) |
column -t |
# sort by instance name and device name
sort -k2,6
