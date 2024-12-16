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
Lists AWS IAM users and their password last used date

See Also:

    - check_aws_users_password_last_used.py in the Advanced Nagios Plugins collection

        https://github.com/HariSekhon/Nagios-Plugins

    awless list users

    awless list users --format tsv | awk '{if(\$4 == \"months\" || \$4 == \"years\") print}'


$usage_aws_cli_jq_required
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args=""

help_usage "$@"

export AWS_DEFAULT_OUTPUT=json

aws iam list-users |
jq -r '.Users[] | [.UserName, .PasswordLastUsed] | @tsv' |
#while read -r username password_last_used; do
#    printf '%s\t%s\n' "$username" "${password_last_used:-N/A}"
#done |
awk '{if(NF==1){$2="N/A"}print}' |
column -t
