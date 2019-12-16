#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2019-12-05 17:02:15 +0000 (Thu, 05 Dec 2019)
#
#  https://github.com/harisekhon/bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/harisekhon
#

# Lists AWS IAM users and the password last used date
#
# See also check_aws_users_password_last_used.py in the Advanced Nagios Plugins collection
#
# - https://github.com/harisekhon/nagios-plugins

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x

aws iam list-users |
jq -r '.Users[] | [.UserName, .PasswordLastUsed] | @tsv' |
column -t
