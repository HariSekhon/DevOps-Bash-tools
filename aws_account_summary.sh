#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-01-07 15:08:44 +0000 (Tue, 07 Jan 2020)
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
Prints AWS account summary in 'key = value' pairs for easy viewing / grepping

Useful information includes whether the root account has MFA enabled and no access keys:

AccountAccessKeysPresent = 0
AccountMFAEnabled = 1

or comparing number of users to number of MFA devices eg.

MFADevices = 6
MFADevicesInUse = 6
...
Users = 14


If you don't have AWS Organizations permissions, you'll probably get an error like this, in which case the account name and root account email won't be printed:

    An error occurred (AccessDeniedException) when calling the DescribeAccount operation: You don't have permissions to access this resource.

This may happen for example when you're using an AWS SSO account that doesn't have privileges at the Organization level to describe the account.
This can be safely ignored, the rest of the IAM account summary info containing details such as MFA devices, users and policies etc will be there.


See Also:

    aws_iam_users_mfa_active_report.sh (adjacent)
    check_aws_root_account.py   -   in The Advanced Nagios Plugins collection (https://github.com/HariSekhon/Nagios-Plugins)


$usage_aws_cli_required
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<aws_profile>]"

help_usage "$@"

# XXX: can't set this to account_id as account summary info only works on a profile basis
profile="${1:-}"

if [ -n "$profile" ]; then
    export AWS_PROFILE="$profile"
fi

export AWS_DEFAULT_OUTPUT=json

account_id="$(aws sts get-caller-identity --query Account --output text | tr -d '\r')"
echo "AccountID = $account_id"
# XXX: might not have permissions to run this one, skip it if so
account_info="$(aws organizations describe-account --account-id "$account_id" || { echo; echo "Missing permission to describe AWS Organization"; echo; } >&2 )"
if [ -n "$account_info" ]; then
    account_name="$(jq -r '.Account.Name' <<< "$account_info")"
    echo "AccountName = $account_name"
    account_email="$(jq -r '.Account.Email' <<< "$account_info")"
    echo "AccountEmail = $account_email"
fi
aws iam get-account-summary |
jq -r '.SummaryMap | to_entries | map(.key + " = " + (.value | tostring)) | .[]' |
sort
