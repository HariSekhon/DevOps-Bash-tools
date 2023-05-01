#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#  args: haritest-terraform-state-lock-table
#
#  Author: Hari Sekhon
#  Date: 2022-05-27 17:36:29 +0100 (Fri, 27 May 2022)
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
Creates a DynamoDB table for Terraform state locking

Also creates a policy for a permission limited Terraform account to use to lock/unlock the table.
This is useful when creating a Read Only account for GitHub Actions environment secret for Pull Requests to not need workflow approval

Idempotent - skips creation of table and policy if they already exist


$usage_aws_cli_required
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<table_name> [<aws_cli_options>]"

help_usage "$@"

min_args 1 "$@"

table="$1"
shift || :

export AWS_DEFAULT_OUTPUT=json

aws_account_id="$(aws_account_id)"
aws_region="$(aws_region)"

timestamp "Checking for existing DynamoDB table '$table'"
if aws dynamodb list-tables "$@" | jq -r '.TableNames[]' | grep -Fxq "$table"; then
    timestamp "WARNING: table '$table' already exists in region '$aws_region', not creating..."
else
    timestamp "Creating Terraform DynamoDB table '$table' in region '$aws_region'"
    aws dynamodb create-table --table-name "$table" \
                              --key-schema AttributeName=LockID,KeyType=HASH \
                              --attribute-definitions AttributeName=LockID,AttributeType=S \
                              --billing-mode PAY_PER_REQUEST \
                              "$@"
    timestamp "DynamoDB table created"
fi

echo

policy="Terraform-DynamoDB-Lock-Table-$table"

timestamp "Generating policy document '$policy'"
policy_document="$(cat <<EOF
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
            "Resource": "arn:aws:dynamodb:$aws_region:$aws_account_id:table/$table"
        }
    ]
}
EOF
)"

timestamp "Checking for existing policy"
set +o pipefail  # early termination from the pipeline will fail the check otherwise
if aws iam list-policies | jq -r '.Policies[].PolicyName' | grep -Fxq "$policy"; then
    timestamp "WARNING: policy '$policy' already exists, not creating..."
else
    timestamp "Creating Terraform DynamoDB Policy '$policy'"
    aws iam create-policy --policy-name "$policy" --policy-document "$policy_document"
    timestamp "DynamoDB policy created"
fi
