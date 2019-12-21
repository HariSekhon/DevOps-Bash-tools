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

# Quick script to dump all users access key status and age
#
# CSV Output format:
#
# user,access_key_1_active,access_key_1_last_rotated,access_key_2_active,access_key_2_last_rotated
#
#
# See also:
#
# aws_users_access_key_age.py
#
# in DevOps Python Tools which is able to filter by age and status
#
# https://github.com/harisekhon/devops-python-tools
#
# awless list accesskeys --format tsv | grep 'years[[:space:]]*$'

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(dirname "${BASH_SOURCE[0]}")"

"$srcdir/aws_iam_generate_credentials_report_wait.sh" >&2

if [ "$(uname -s)" = Darwin ]; then
    base64_decode="base64 -D"
else
    base64_decode="base64 -d"
fi

aws iam get-credential-report --query 'Content' --output text |
$base64_decode |
cut -d, -f1,9,10,14,15
