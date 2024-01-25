#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2022-06-15 18:41:42 +0100 (Wed, 15 Jun 2022)
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
Finds all users, groups and roles where a given IAM policy is attached, so that you can remove all these references in your Terraform code and avoid this error:

Plan: 1 to add, 1 to change, 1 to destroy.
module.mymodule.aws_iam_policy.mypolicy: Destroying... [id=arn:aws:iam::***:policy/mypolicy]
╷
│Error: error deleting IAM policy arn:aws:iam::***:policy/mypolicy: DeleteConflict: Cannot delete a policy attached to entities.
│    status code: 409, request id: 1f9ca3ee-48fb-4e5e-9e58-5c266e29e9be

"

help_usage "$@"

min_args 1 "$@"

policy="$1"

export AWS_DEFAULT_OUTPUT=json

aws_account_id="$(aws_account_id)"

policy_arn="arn:aws:iam::$aws_account_id:policy/$policy"

find_entities(){
    local entity_type="$1"
    aws iam list-entities-for-policy --policy-arn "$policy_arn" |
    jq_debug_pipe_dump |
    jq -r ".Policy${entity_type}s[].${entity_type}Name" |
    while read -r entity; do
        printf '%s\t%s\n' "$entity_type" "$entity"
    done
}

find_entities User
find_entities Group
find_entities Role
