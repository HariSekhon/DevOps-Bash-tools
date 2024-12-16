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
Resizes an EBS volume and waits for it to complete modifying and optionally optimizing with exponential backoff

This can be done without interruption while the EC2 instance is online

If you want to wait for the optimization as well as the modification set this environment variable

    export EC2_EBS_WAIT_FOR_OPTIMIZE=true

Use the adjacent script aws_ec2_ebs_volumes.sh to easily get the volume ID


$usage_aws_cli_jq_required
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<ebs_volume_id> <size_in_GB>"

help_usage "$@"

# enforce giving a 2nd arg for description
num_args 2 "$@"

volume_id="$1"
size="$2"

aws_validate_volume_id "$volume_id"

export MAX_WATCH_SLEEP_SECS=300

export AWS_DEFAULT_OUTPUT=json

timestamp "Resizing volume ID '$volume_id' to $size GB"
ebs_modification="$(aws ec2 modify-volume --volume-id "$volume_id" --size 300 --output json)"

modification_starttime="$(jq -r '.VolumeModification.StartTime' <<< "$ebs_modification")"
echo

optimize_filter=()
if [ "${EC2_EBS_WAIT_FOR_OPTIMIZE:-}" = true ]; then
    optimize_filter=(--filters "Name=modification-state,Values=optimizing")
fi

get_aws_pending_ebs_modifications(){
    # cannot quote $optimize_filter because we need it to not create a blank arg if not present
    # shellcheck disable=SC2086
    aws ec2 describe-volumes-modifications \
        --volume-ids "$volume_id" \
        --filters "Name=modification-state,Values=modifying" \
        "${optimize_filter[@]}" \
        --output text
}

# will double this for exponential backoff up to MAX_WATCH_SLEEP_SECS interval
sleep_secs=5

# loop indefinitely until we explicitly break using time check
while : ; do
    if [ "$SECONDS" -gt 7200 ]; then
        die "Timed out waiting 2 hours for EBS snapshot to modify and optimize!"
    fi
    if get_aws_pending_ebs_modifications | tee /dev/stderr | grep -Fq "$modification_starttime"; then
        echo
        timestamp "EBS modification still in progress, waiting $sleep_secs secs before checking again"
        sleep "$sleep_secs"
        # exponential backoff
        sleep_secs="$(exponential "$sleep_secs" "$MAX_WATCH_SLEEP_SECS")"
        continue
    fi
    break
done

echo
timestamp "EBS resize modification completed"
