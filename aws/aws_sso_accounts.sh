#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2024-11-20 18:19:53 +0400 (Wed, 20 Nov 2024)
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
Lists all the AWS SSO accounts you have access to

Requires you to already be logged in to AWS SSO in order to use the access token to list the accounts

If you are not currently authenticated, with prompt to log you in first

Output is tab-delimited:

<account_id>    <root_account_email>    <account_name>


The account name is last because it may contain spaces and this is easier to

$usage_aws_cli_required
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args=""

help_usage "$@"

num_args 0 "$@"

if ! is_aws_sso_logged_in; then
    # output to stderr so that if we are collecting the output from this script,
    # we do not collect any output from sso login
    aws sso login 2>&1
fi

# find is not as good for finding the sorted latest cache file
# shellcheck disable=SC2012
latest_sso_cache_file="$(ls -t ~/.aws/sso/cache/*.json | head -n1)"

access_token="$(jq -r .accessToken < "$latest_sso_cache_file")"

# awk preprocessing trick to not split the third column name which can contain spaces as then it'd looks weird
aws sso list-accounts --access-token "$access_token" |
jq -r '.accountList[] | [.accountId, .emailAddress, .accountName] | @tsv' |
sort -fuk 3 |
awk '{printf "%s\t%s\t", $1, $2; $1=""; $2=""; print}' |
column -t -s $'\t'
