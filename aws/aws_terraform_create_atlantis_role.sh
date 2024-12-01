#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2024-12-02 04:27:26 +0700 (Mon, 02 Dec 2024)
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
Creates an AWS IAM role called 'atlantis' with an optional suffix and attaches the Administrator policy


$usage_aws_cli_required
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<atlantis_role_suffix> <atlantis_aws_account_id>]"

help_usage "$@"

max_args 1 "$@"

suffix="${1:-}"

aws_account_id="${2:-}"

role_name="atlantis"

if [ -n "$suffix" ]; then
	role_name="$role_name-$suffix"
fi

if [ -n "$aws_account_id" ]; then
    if ! is_aws_account_id "$aws_account_id"; then
        usage "Invalid AWS account ID given for where Atlantis is running, failed reged validation: $aws_account_id"
    fi
else
    aws_account_id="$(aws_account_id)"
fi

trust_policy=$(cat <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::$aws_account_id:root"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
)

if aws iam get-role --role-name "$role_name" >/dev/null 2>&1; then
    timestamp "Role '$role_name' already exists, skipping creation"
	exit 0
fi

timestamp "Creating IAM role '$role_name'..."
aws iam create-role \
    --role-name "$role_name" \
    --assume-role-policy-document "$trust_policy" \
    --description "Role for Atlantis with AdministratorAccess"
echo >&2

timestamp "Attaching AdministratorAccess policy to role '$role_name'..."
aws iam attach-role-policy \
    --role-name "$role_name" \
    --policy-arn "arn:aws:iam::aws:policy/AdministratorAccess"
echo >&2

timestamp "AWS IAM role '$role_name' created and AdministratorAccess policy attached"
