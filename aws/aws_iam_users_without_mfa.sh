#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2019-12-19 10:02:31 +0000 (Thu, 19 Dec 2019)
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
Lists AWS IAM users with passwords enabled but without MFA enabled

Outputs a list of users, one per line.


Uses the adjacent script aws_iam_users_mfa_active_report.sh


See similar tools in the DevOps Python Tools repo and The Advanced Nagios Plugins Collection:

    - https://github.com/HariSekhon/DevOps-Python-tools
    - https://github.com/HariSekhon/Nagios-Plugins


$usage_aws_cli_required
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args=""

help_usage "$@"

"$srcdir/aws_iam_users_mfa_active_report.sh" |
awk -F, '$2 !~ "false" {print}' |
sed '/,true$/d' |
tail -n +2 |
awk -F, '{print $1}'
