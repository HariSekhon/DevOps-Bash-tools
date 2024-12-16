#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2022-05-31 10:25:27 +0100 (Tue, 31 May 2022)
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
Checks S3 public access is blocked at the AWS Account level

First arg must be the AWS Account ID. If not given and \$AWS_ACCOUNT_ID is set, will use that, otherwise will infer from the current access key

Raw JSON is output to stdout
OK/WARNING Status is output to stderr
Exits with error code 1 if S3 public access is set and exit code 2 if not fully blocked via policy at the account level


$usage_aws_cli_jq_required
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<aws_account_id>"

help_usage "$@"

max_args 1

aws_account_id="${1:-}"
shift || :

if [ -z "$aws_account_id" ]; then
    if [ -n "${AWS_ACCOUNT_ID:-}" ]; then
        aws_account_id="$AWS_ACCOUNT_ID"
    else
        timestamp "inferring AWS account id from access key"
        aws_account_id="$(aws_account_id)"
        timestamp "inferred AWS account id to be '$aws_account_id'"
    fi
fi

export AWS_DEFAULT_OUTPUT=json

shopt -s nocasematch

output="$(aws s3control get-public-access-block --account-id "$aws_account_id" || :)"
if [ -n "$output" ]; then
    echo "$output"
    # XXX: must align with read command a few lines down
    policy="$(jq -r '.PublicAccessBlockConfiguration | [ .BlockPublicAcls, .IgnorePublicAcls, .BlockPublicPolicy, .RestrictPublicBuckets ] | @tsv' <<< "$output")"
    read -r BlockPublicAcls IgnorePublicAcls BlockPublicPolicy RestrictPublicBuckets <<< "$policy"
    if [[ "$BlockPublicAcls" =~ false ]] ||
       [[ "$IgnorePublicAcls" =~ false ]] ||
       [[ "$BlockPublicPolicy" =~ false ]] ||
       [[ "$RestrictPublicBuckets" =~ false ]]; then
        echo "WARNING: Block Public Access policy is not enabled at the account level for AWS Account '$aws_account_id'! " >&2
        exit 2
    else
        echo "OK: Block Public Access policy is enabled at the account level for AWS Account '$aws_account_id'" >&2
    fi
else
    echo "WARNING: Block Public Access policy is not set at the account level for AWS Account '$aws_account_id'! " >&2
    exit 1
fi
