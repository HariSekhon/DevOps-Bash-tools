#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2019-12-19 10:02:31 +0000 (Thu, 19 Dec 2019)
#
#  https://github.com/harisekhon/bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/harisekhon
#

# Lists AWS IAM users the dates of their last password and access key usage
#
# Output format is CSV with the following headers
#
# user,password_last_used,access_key_1_last_used_date,access_key_2_last_used_date
#
# Add
#
# | grep -B1 '<root_account>'
#
# to check your root account isn't being used
#
# See similar tools in the DevOps Python Tools repo and The Advanced Nagios Plugins Collection:
#
# - https://github.com/harisekhon/devops-python-tools
# - https://github.com/harisekhon/nagios-plugins

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(dirname "${BASH_SOURCE[0]}")"

"$srcdir/aws_iam_generate_credentials_report_wait.sh" >&2

if [ "$(uname -s)" = Darwin ]; then
    base64_decode="base64 -D"
else
    base64_decode="base64 -d"
fi

# not documented in 'aws iam get-credential-report help'
aws iam get-credential-report --query 'Content' --output text |
$base64_decode |
cut -d, -f1,5,11,16
