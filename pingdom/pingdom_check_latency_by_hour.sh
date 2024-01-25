#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-08-24 15:59:30 +0100 (Mon, 24 Aug 2020)
#
#  https://github.com/HariSekhon/DevOps-Bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/HariSekhon
#

# https://docs.pingdom.com/api/#tag/Summary.hoursofday

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck disable=SC1090,SC1091
. "$srcdir/lib/utils.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Gets average latency per hour of the day, averaged over the last week, for a given Pingdom check via the Pingdom API

Output format - quoted CSV:

<hour_of_day>,<average_latency_in_ms>

For TSV format, set TSV=1 environment variable


To find check IDs:

    pingdom_checks.sh


\$PINGDOM_TOKEN must be defined in the environment for authentication

See adjacent pingdom_api.sh for more details
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<check_id> [<curl_options>]"

help_usage "$@"

min_args 1 "$@"

check_id="$1"
shift || :

{
echo "hour,latency_ms"
# could set from=<epoch>&to=<epoch> - defaults to 1 week to now
"$srcdir/pingdom_api.sh" "/summary.hoursofday/$check_id" "$@" |
jq -r '.hoursofday[] | [.hour, .avgresponse] | @csv'
} |
if [ -n "${TSV:-}" ]; then
    column -t -s , |
    sed 's/"//g'
else
    cat
fi
