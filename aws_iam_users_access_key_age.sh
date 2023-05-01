#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2019-12-05 17:02:15 +0000 (Thu, 05 Dec 2019)
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
Prints users access key status and age

See Also:

    aws_iam_users_access_key_age_report.sh - much quicker version for lots of users


    aws_users_access_key_age.py - in DevOps Python Tools which is able to filter by age and status

    https://github.com/HariSekhon/DevOps-Python-tools


    awless list accesskeys --format tsv | grep 'years[[:space:]]*$'


AWS Config rule compliance:

    https://<region>.console.aws.amazon.com/config/home?region=<region>&v2=true#/rules/details?configRuleName=access-keys-rotated

eg.

    https://eu-west-1.console.aws.amazon.com/config/home?region=eu-west-1&v2=true#/rules/details?configRuleName=access-keys-rotated


$usage_aws_cli_required
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args=""

help_usage "$@"

export AWS_DEFAULT_OUTPUT=json

echo "output will be formatted in to columns at end" >&2
echo "getting user list" >&2
aws iam list-users |
jq -r '.Users[].UserName' |
while read -r username; do
    echo "querying user $username" >&2
    aws iam list-access-keys --user-name "$username" |
    jq -r '.AccessKeyMetadata[] | [.UserName, .Status, .CreateDate, .AccessKeyId] | @tsv'
done |
column -t
