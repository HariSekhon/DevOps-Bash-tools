#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2024-12-03 09:47:12 +0700 (Tue, 03 Dec 2024)
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
Deletes a bucket including all versions

DANGER: this beats the safety mechanisms if you really want to delete some PoC bucket. Use with caution!

Requires AWS CLI to be installed and configured
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
#usage_args="[<aws_sso_args>]"
usage_args="<bucket_name>"

help_usage "$@"

num_args 1 "$@"

bucket="$1"
bucket="${bucket#s3://}"

timestamp "Getting object versions for bucket: $bucket"
object_versions="$(
    aws s3api list-object-versions \
        --bucket "$bucket" \
        --query 'Versions[].{Key: Key, VersionId: VersionId}' \
        --output text
)"

if [ "$object_versions" != "None" ]; then
    while read -r key versionId; do
        timestamp "Deleting object '$key' version '$versionId'"
        aws s3api delete-object --bucket "$bucket" --key "$key" --version-id "$versionId"
    done <<< "$object_versions"
    echo >&2
fi

timestamp "Getting object deletion markers for bucket: $bucket"
object_deletion_markers="$(
    aws s3api list-object-versions \
        --bucket "$bucket" \
        --query 'DeleteMarkers[].{Key: Key, VersionId: VersionId}' \
        --output text
)"

if [ "$object_deletion_markers" != "None" ]; then
    while read -r key versionId; do
        timestamp "Deleting object deletion marker '$key' version '$versionId'"
        aws s3api delete-object --bucket "$bucket" --key "$key" --version-id "$versionId"
    done <<< "$object_deletion_markers"
    echo >&2
fi

timestamp "Deleting bucket: $bucket"
#aws s3api delete-bucket --bucket "$bucket"
aws s3 rb "s3://$bucket"
