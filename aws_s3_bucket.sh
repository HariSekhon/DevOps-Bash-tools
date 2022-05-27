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

# shellcheck disable=SC1090
. "$srcdir/lib/aws.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Creates an S3 bucket with the following optimizations:

- Enables Versioning
- Enables MFA Delete protection (only if you CLI is MFA authenticated)
- Enables Server Side Encryption
- Optionally locks out any additional given user/group/role ARNs

Idempotent: skips bucket creation is already exists, applies versioning and encryption, applies bucket policy is none exists of if \$OVERWRITE_BUCKET_POLICY is set to any value

Region: will create the bucket in your configured region, to override locally set \$AWS_DEFAULT_REGION


$usage_aws_cli_required
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<bucket_name> [<ARNs_to_block_access_from>]"

help_usage "$@"

min_args 1 "$@"

bucket="$1"
shift || :

arns_to_block=("$@")

export AWS_DEFAULT_OUTPUT=json

if ! aws s3 ls "s3://$bucket" &>/dev/null; then
	timestamp "Creating S3 bucket"
	aws s3 mb "s3://$bucket" || :
	echo >&2
fi

timestamp "Enabling S3 versioning"
aws s3api put-bucket-versioning --bucket "$bucket" --versioning-configuration 'Status=Enabled'
timestamp "Versioning enabled"
echo >&2

timestamp "Enabling S3 MFA Delete (only works if you are MFA authenticated)"
if aws s3api put-bucket-versioning --bucket "$bucket" --versioning-configuration 'MFADelete=Enabled,Status=Enabled'; then
    timestamp "MFA Delete enabled"
else
    timestamp "WARNING: MFA Delete setting failed, must enable manually if not calling this script from an MFA enabled session"
fi
echo >&2

timestamp "Enabling S3 server-side encryption"
aws s3api put-bucket-encryption --bucket "$bucket" --server-side-encryption-configuration '{"Rules": [{"ApplyServerSideEncryptionByDefault": {"SSEAlgorithm": "AES256"}}]}'
timestamp "Encryption enabled"
echo >&2

timestamp "Enabling S3 Block Public Access"
aws s3api put-public-access-block --bucket "$bucket" --public-access-block-configuration 'BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true'
timestamp "Blocked public access"
echo >&2

if [ -n "${arns_to_block[*]}" ]; then
    if [ -z "${OVERWRITE_BUCKET_POLICY:-}" ] && \
       timestamp "Checking for existing S3 bucket policy" && \
       [ -n "$(aws s3api get-bucket-policy --bucket "$bucket" --query Policy --output text 2>/dev/null)" ]; then
        timestamp "WARNING: bucket policy already exists, not overwriting for safety, must edit manually"
    else
        timestamp "Creating bucket policy to lock out given ARNs:"
        echo >&2
        for arn in "${arns_to_block[@]}"; do
            printf '\t%s\n' "$arn" >&2
        done
        echo >&2
        aws s3api put-bucket-policy --bucket "$bucket" --policy "$(cat <<EOF
{
  "Id": "Policy1653672260380",
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "DisallowedUserGroupRoleArns",
      "Action": "s3:*",
      "Effect": "Deny",
      "Resource": [
        "arn:aws:s3:::$bucket",
        "arn:aws:s3:::$bucket/*"
      ],
      "Principal": {
        "AWS": [
$(
    for arn in "${arns_to_block[@]}"; do
        # pad by 10 spaces using an empty first arg
        printf '%10s"%s",\n' "" "$arn"
    done |
    sed '$ s/,$//'
)
        ]
      }
    }
  ]
}
EOF
)"
		timestamp "Bucket policy created"
    fi
fi
