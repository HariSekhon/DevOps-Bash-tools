#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2021-02-20 17:26:21 +0000 (Sat, 20 Feb 2021)
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
Creates an AWS service account for CI/CD automation or AWS CLI to avoid having to re-login every day via SSO with 'aws sso login'

Grants this service account Administator privileges in the current AWS account unless an alternative group or policy is specified

Creates an IAM access key (deleting an older unused key if necessary), writes a CSV just as the UI download would, and outputs both shell export commands and configuration in the format for copying to your AWS profile in ~/.aws/credentials

The following optional arguments can be given:

- user name         (default: \$USER-cli)
- keyfile           (default: ~/.aws/keys/\${user}_\${aws_account_id}_accessKeys.csv) - be careful if specifying this, a non-existent keyfile will create a new key, deleting the older of 2 existing keys if necessary to be able to create this
- group/policy      (default: Admins group or falls through to AdministratorAccess policy - checks for this group name first, or else policy by this name)

This can also be used as a backup credential - this way if something accidentally happens to your AWS SSO you can still get into your account

Idempotent - safe to re-run, will skip creating a user that already exists or CSV export that already exists


$usage_aws_cli_jq_required
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<username> [<group1,group2,policy1,policy2...> <keyfile>]"

help_usage "$@"

#min_args 1 "$@"

user="${1:-$USER-cli}"

#group="${2:-Admins}"
#policy="${2:-AdministratorAccess}"
groups_or_policies="${2:-}"
default_group="Admins"
default_policy="AdministratorAccess"

aws_account_id="$(aws_account_id)"

access_keys_csv="${3:-$HOME/.aws/keys/${user}_${aws_account_id}_accessKeys.csv}"

export AWS_DEFAULT_OUTPUT=json

aws_create_user_if_not_exists "$user"

exports="$(aws_create_access_key_if_not_exists "$user" "$access_keys_csv")"

group_exists(){
    # causes a failure in the if policy test condition, probably due to early exit on one of the pipe commands
    set +o pipefail
    aws iam list-groups | jq -r '.Groups[].GroupName' | grep -Fixq "$1" || return 1
    set -o pipefail
}

policy_exists(){
    # causes a failure in the if policy test condition, probably due to early exit on one of the pipe commands
    set +o pipefail
    aws iam list-policies | jq -r '.Policies[].PolicyName' | grep -Fixq "$1" || return 1
    set -o pipefail
}

grant_group_or_policy(){
    local group_or_policy="$1"
    if group_exists "$group_or_policy"; then
        group="$group_or_policy"
        timestamp "Adding user '$user' to group '$group' on account '$aws_account_id'"
        aws iam add-user-to-group --user-name "$user" --group-name "$group"
    elif policy_exists "$group_or_policy"; then
        policy="$group_or_policy"
        timestamp "Determining ARN for policy '$policy'"
        policy_arn="$(aws iam list-policies | jq -r ".Policies[] | select(.PolicyName == \"$policy\") | .Arn")"
        timestamp "Determined policy ARN:  $policy_arn"
        timestamp "Granting policy '$policy' permissions directly to user '$user' in account '$aws_account_id'"
        aws iam attach-user-policy --user-name "$user" --policy-arn "$policy_arn"
    else
        die "Group/Policy '$group_or_policy' not found in account '$aws_account_id'"
    fi
    echo
}

if [ -n "$groups_or_policies" ]; then
    for group_or_policy in ${groups_or_policies//,/ }; do
        grant_group_or_policy "$group_or_policy"
    done
else
    if group_exists "$default_group"; then
        grant_group_or_policy "$default_group"
    elif policy_exists "$default_policy"; then
        grant_group_or_policy "$policy"
    else
        die "Neither default group '$default_group', nor default policy '$default_policy' in account '$aws_account_id'"
    fi
fi

echo
echo "Set the following export commands in your environment to begin using this access key in your CLI immediately:"
echo
echo "$exports"
echo
echo "or add the following to your ~/.aws/credentials file:"
echo
aws_access_keys_exports_to_credentials <<< "$exports"
echo
echo
