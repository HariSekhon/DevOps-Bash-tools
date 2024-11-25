#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2024-11-20 18:30:58 +0400 (Wed, 20 Nov 2024)
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
Generates AWS SSO configs for all AWS SSO accounts the currently logged in user has access to

Requires you to already be logged in to AWS SSO in order to use the access token to list the accounts

If you are not currently authenticated, with prompt to log you in first


Config contents:

.   These assume you are using the same config for each SSO account. Edit the resulting config otherwise

    Start URL - infers from current config

    ROLE - infers from current role. Set AWS_DEFAULT_ROLE, AWS_ROLE or ROLE environment variables to override this in that order of precedence

    REGION - infers from current config. Set the standard AWS environment variable AWS_DEFAULT_REGION, or alternatively AWS_REGION or REGION in that order of precedence, otherwise it will default to eu-west-1 if all of the previous inferences fail


Uses the adjacent script to get the AWS Account ID and Name for each SSO account:

    aws_sso_accounts.sh


$usage_aws_cli_required
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args=""

help_usage "$@"

num_args 0 "$@"

export aws_default_region="eu-west-1"

# force functions to log with timestamps
export VERBOSE=1

aws_sso_login_if_not_already

access_token="$(aws_sso_token)"

role="$(aws_sso_role)"
echo >&2

region="$(aws_region_from_env)"

sso_start_url="$(aws_sso_start_url)"
echo >&2

sso_start_region="$(aws_sso_start_region)"
echo >&2

timestamp "Getting AWS SSO accounts this account has access to"
"$srcdir/aws_sso_accounts.sh" |
while read -r id _email name; do
    name="$(tr '[:upper:]' '[:lower:]' <<< "$name" | sed 's/[^[:alnum:]]/-/g')"
    timestamp "Looking up available roles for account '$name' ($id)"
    roles="$(
        aws sso list-account-roles \
            --account-id "$id" \
            --access-token "$access_token" \
            --query 'roleList[*].roleName' \
            --output text |
        tr '[:space:]' '\n'
    )"
    if grep -Fxq "$role" <<< "$roles"; then
        timestamp "Role '$role' is available on account '$name' ($id), using it for config"
        sso_role="$role"
    else
        timestamp "Role '$role' not available on account '$name' ($id) - available roles:"
        echo >&2
        echo "$roles" >&2
        echo >&2
        sso_role="$(head -n1 <<< "$roles")"
        timestamp "Using first available role '$sso_role' for account '$name' ($id) - edit to another role if necessary"
    fi
    echo >&2
    cat <<EOF
[profile $name]
sso_start_url  = $sso_start_url
sso_region     = $sso_start_region
sso_account_id = $id
sso_role_name  = $sso_role
region         = $region

EOF
done
