#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#  shellcheck disable=SC1091
#
#  Author: Hari Sekhon
#  Date: 2024-11-22 14:20:14 +0400 (Fri, 22 Nov 2024)
#
#  https///github.com/HariSekhon/DevOps-Bash-tools
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
Lists AWS deployed resources in the current or specified AWS account profile

Written to be combined with aws_foreach_profile.sh


$usage_aws_cli_required
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<aws_profile>]"

help_usage "$@"

max_args 1 "$@"

check_bin aws

if [ $# -gt 0 ]; then
    aws_profile="$1"
    shift || :
    export AWS_PROFILE="$aws_profile"
fi

aws_account_id="$(aws_account_id)"

"$srcdir/aws_info_ec2_csv.sh" |
sed "s|^|\"$aws_account_id\",|"
