#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2022-06-15 15:21:27 +0100 (Wed, 15 Jun 2022)
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
. "$srcdir/lib/utils.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Creates a Terraform CLI machine account, S3 bucket and DynamoDB locking table with policy for restricted accounts

Required:

- account name      used to suffix S3 bucket, DynamoDB table and policy names

Optional:

- user name         (default: \$USER-terraform)
- group or policy   (default: Admins group if found, else AdministratorAccess standard AWS-managed policy)
- keyfile           (default: ~/.aws/keys/\${user}_\${aws_account_id}_accessKeys.csv) - be careful if specifying this, a non-existent keyfile will create a new key, deleting the older of 2 existing keys if necessary to be able to create this

Examples:

    # create buckets, tables and user with all IAM policies for an account called 'myaccount' and a user called 'github-actions-myrepo'

        ${0##*/} myaccount github-actions-terraform  # gets AdministratorAccess by default

        ${0##*/} myaccount github-actions-terraform-plan ReadOnly

"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<account_name> [<username> <group_or_policy> <keyfile>]"

help_usage "$@"

min_args 1 "$@"
max_args 4 "$@"

account_name="$1"
user="${2:-$USER-terraform}"
group_or_policy="${3:-}"
keyfile="${4:-}"

bucket="terraform-state-$account_name"
table="terraform-state-$account_name"

# must match the name generated in aws_terraform_create_dynamodb_table.sh
dynamodb_policy="Terraform-DynamoDB-Lock-Table-$table"

"$srcdir/aws_terraform_create_s3_bucket.sh" "$bucket"

echo

"$srcdir/aws_terraform_create_dynamodb_table.sh" "$table"

echo

s3_policy="Terraform-S3-Bucket-$bucket"

timestamp "Generating policy document '$s3_policy'"
s3_policy_document="$(cat <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "TerraformS3Bucket",
            "Effect": "Allow",
            "Action": [
                "s3:GetObject",
                "s3:PutObject"
            ],
            "Resource": [
                "arn:aws:s3:::$bucket/*"
            ]
        }
    ]
}
EOF
)"

timestamp "Checking if policy '$s3_policy' exists"
set +o pipefail  # early termination from the pipeline will fail the check otherwise
if aws iam list-policies | jq -r '.Policies[].PolicyName' | grep -Fxq "$s3_policy"; then
    timestamp "WARNING: policy '$s3_policy' already exists, not creating..."
else
    timestamp "Creating Terraform S3 Policy '$s3_policy'"
    aws iam create-policy --policy-name "$s3_policy" --policy-document "$s3_policy_document"
    timestamp "Policy created"
fi
set -o pipefail
echo

"$srcdir/aws_terraform_create_credential.sh" "$user" "$s3_policy,$dynamodb_policy"${group_or_policy:+,"$group_or_policy"} ${keyfile:+"$keyfile"}
