#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2021-10-27 18:23:44 +0100 (Wed, 27 Oct 2021)
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
Gets AWS SSO session credentials as shell export commands for exporting into another system like Terraform Cloud

Extracts the access token from the AWS SSO cache, then uses that to get credentials for the specified role.

If role is 'list', will list the available roles and exit so you can see what roles are valid to enter for that argument, eg. AWSAdministratorAccess or AWSPowerUserAccess


You must have already logged in first:

    aws sso login

You may want to 'export AWS_PROFILE=...' if you have multiple logged in SSO profiles and want to select the right one.

This script will take the latest creds file from ~/.aws/sso/cache
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<role_name>"

help_usage "$@"

min_args 1 "$@"

role="$1"
account_id="$(aws sts get-caller-identity --query Account --output text)"

#account_id="${AWS_ACCOUNT_ID:-}"
#
#if [ -z "$account_id" ]; then
#    if [ -n "${AWS_PROFILE:-}" ]; then
#        timestamp "attempting to infer account id from AWS Profile '$AWS_PROFILE'"
#        account_id="$(sed -n "/^\\[profile $AWS_PROFILE\\]/,/sso_account_id/p" "${AWS_CONFIG_FILE:-~/.aws/config}" | awk -F= '/sso_account_id/{print $2}')"
#    fi
#fi
#if [ -z "$account_id" ]; then
#    min_args 2 "$@"
#    account_id="$2"
#fi

# shellcheck disable=SC2012
latest_cache="$(ls -tr ~/.aws/sso/cache/* | sed '/botocore/d' | tail -n 1)"

read -r region access_token < <(jq -r '[.region, .accessToken] | @tsv' < "$latest_cache")

if [ "$role" = list ]; then
    echo "Roles available for account '$account_id':"
    aws sso list-account-roles --account-id "$account_id" --access-token "$access_token" |
    jq -r '.roleList[].roleName'
    exit 0
fi

aws sso get-role-credentials --account-id "$account_id" --role-name "$role" --region "$region" --access-token "$access_token" |
jq -r '.roleCredentials | [.accessKeyId, .secretAccessKey, .sessionToken] | @tsv' |
while read -r key secret token; do
    echo "export AWS_ACCESS_KEY_ID=$key"
    echo "export AWS_SECRET_ACCESS_KEY=$secret"
    echo "export AWS_SESSION_TOKEN=$token"
done
