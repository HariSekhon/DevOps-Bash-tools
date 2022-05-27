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

# shellcheck disable=SC1090
. "$srcdir/lib/aws.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Creates a DynamoDB table for Terraform state locking

Exits with an error if the table already exists


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

if aws dynamodb list-tables "$@" | jq -r '.TableNames[]' | grep -Fxq "$table"; then
    die "ERROR: table '$table' already exists"
fi

aws dynamodb create-table --table-name "$table" \
                          --key-schema AttributeName=LockID,KeyType=HASH \
                          --attribute-definitions AttributeName=LockID,AttributeType=S \
                          --billing-mode PAY_PER_REQUEST \
                          "$@"
