#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-01-07 15:08:44 +0000 (Tue, 07 Jan 2020)
#
#  https://github.com/harisekhon/bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/harisekhon
#

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck disable=SC1090
. "$srcdir/lib/aws.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Prints AWS account summary in 'key = value' pairs for easy viewing / grepping

Useful information in here is whether the root account has MFA enabled and no access keys:

AccountAccessKeysPresent = 0
AccountMFAEnabled = 1

or comparing number of users to number of MFA devices eg.

MFADevices = 6
MFADevicesInUse = 6
...
Users = 14

See Also:

    aws_users_mfa_active_report.sh (adjacent)
    check_aws_root_account.py   -   in The Advanced Nagios Plugins collection (https://github.com/harisekhon/nagios-plugins)


$usage_aws_cli_required
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args=""

help_usage "$@"


aws iam get-account-summary |
jq -r '.SummaryMap | to_entries | map(.key + " = " + (.value | tostring)) | .[]' |
sort
