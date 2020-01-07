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

# Dumps AWS account summary to key = value pairs for easy viewing / grepping
#
# Useful information in here is whether the root account has MFA enabled and no access keys:
#
# AccountAccessKeysPresent = 0
# AccountMFAEnabled = 1
#
# or comparing number of users to number of MFA devices eg.
#
# MFADevices = 6
# MFADevicesInUse = 6
# ...
# Users = 14
#
# See Also:
#
#   aws_users_mfa_active_report.sh

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x

aws iam get-account-summary |
jq -r '.SummaryMap | to_entries | map(.key + " = " + (.value | tostring)) | .[]' |
sort
