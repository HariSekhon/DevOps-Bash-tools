#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-01-10 17:33:07 +0000 (Fri, 10 Jan 2020)
#
#  https://github.com/harisekhon/bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/harisekhon
#

# Quick script to dump all users MFAs serial numbers to differentiate Virtual vs Hardward MFAs
#
# Virtual MFAs have a SerialNumber in the format:
#
# arn:aws:iam::<account_id>:mfa/<mfa>

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x

aws iam list-virtual-mfa-devices |
jq -r '.VirtualMFADevices[] | [.User.UserName, .SerialNumber] | @tsv' |
column -t
