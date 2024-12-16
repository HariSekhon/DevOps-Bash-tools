#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#  args: haritest-terraform-state-lock-table
#
#  Author: Hari Sekhon
#  Date: 2022-06-15 17:57:17 +0100 (Wed, 15 Jun 2022)
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
Creates IAM policies for S3 buckets and DynamoDB tables containing 'terraform-state' or 'tf-state' in their name

Attaches these policies to the specified user, which must already exist (run aws_terraform_create_credential.sh first)

Necessary for limited privilege CI/CD accounts such as GitHub Actions pull request Terraform Plan only workflows using a Read Only account

Idempotent, skips creation of the policies if they already exist


$usage_aws_cli_jq_required
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<user_name> [<aws_cli_options>]"

help_usage "$@"

min_args 1 "$@"

user="$1"
shift || :

export AWS_DEFAULT_OUTPUT=json

aws_account_id="$(aws_account_id)"

dynamodb_policy="Terraform-DynamoDB-Lock-Tables"
s3_policy="Terraform-S3-Buckets"

timestamp "Generating S3 policy document '$s3_policy'"
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
                "arn:aws:s3:::*tf-state*",
                "arn:aws:s3:::*terraform-state*"
            ]
        }
    ]
}
EOF
)"

timestamp "Generating DynamoDB policy document '$dynamodb_policy'"
dynamodb_policy_document="$(cat <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "TerraformLock",
            "Effect": "Allow",
            "Action": [
                "dynamodb:PutItem",
                "dynamodb:DeleteItem"
            ],
            "Resource": [
                "arn:aws:dynamodb:*:$aws_account_id:table/*terraform-state*",
                "arn:aws:dynamodb:*:$aws_account_id:table/*tf-state*"
            ]
        }
    ]
}
EOF
)"

echo

create_policy(){
    local policy="$1"
    local policy_document="$2"
    timestamp "Checking if policy '$policy' exists"
    set +o pipefail  # early termination from the pipeline will fail the check otherwise
    if aws iam list-policies | jq -r '.Policies[].PolicyName' | grep -Fxq "$policy"; then
        timestamp "WARNING: policy '$policy' already exists, not creating..."
    else
        timestamp "Creating Terraform policy '$policy'"
        aws iam create-policy --policy-name "$policy" --policy-document "$policy_document"
        timestamp "Policy created"
    fi
    set -o pipefail
    echo
}

attach_policy(){
    local policy="$1"
    timestamp "Attaching policy '$policy' to user '$user'"
    timestamp "Determining ARN for policy '$policy'"
    policy_arn="$(aws iam list-policies | jq -r ".Policies[] | select(.PolicyName == \"$policy\") | .Arn")"
    timestamp "Determined policy ARN:  $policy_arn"
    timestamp "Granting policy '$policy' permissions directly to user '$user' in account '$aws_account_id'"
    aws iam attach-user-policy --user-name "$user" --policy-arn "$policy_arn"
    echo
}

create_policy "$dynamodb_policy" "$dynamodb_policy_document"
create_policy "$s3_policy" "$s3_policy_document"
attach_policy "$dynamodb_policy"
attach_policy "$s3_policy"

timestamp "Done"
