#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#  args: haritest-terraform-state
#
#  Author: Hari Sekhon
#  Date: 2022-05-27 18:03:32 +0100 (Fri, 27 May 2022)
#
#  https://github.com/HariSekhon/DevOps-Bash-tools
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
Blocks all public access for given S3 bucket(s) or files containing one bucket per line


$usage_aws_cli_required
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<buckets_or_files>"

help_usage "$@"

min_args 1 "$@"

export AWS_DEFAULT_OUTPUT=json

block_bucket_public_access(){
    local bucket="$1"
    timestamp "Enabling S3 Block Public Access for bucket '$bucket'"
    aws s3api put-public-access-block --bucket "$bucket" --public-access-block-configuration 'BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true'
    timestamp "Blocked public access"
    echo >&2
}

for arg in "$@"; do
    if [ -f "$arg" ]; then
        while read -r bucket; do
            block_bucket_public_access "$bucket"
        done < "$arg"
    else
        block_bucket_public_access "$arg"
    fi
done
