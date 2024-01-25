#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-08-24 13:14:16 +0100 (Mon, 24 Aug 2020)
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
. "$srcdir/lib/utils.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Lists the status periods (outages) for a given Pingdom check for the last year (now - 12 months) via the Pingdom API

Output format - quoted CSV:

\"<status>\",\"<duration_in_seconds>\",\"<from_timestamp>\",\"<to_timestamp>\"

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

epoch_1_year_ago="$(date "+%s" -d "1 year ago")"

"$srcdir/pingdom_api.sh" "/summary.outage/$check_id?from=$epoch_1_year_ago" "$@" |
jq -r '.summary.states[] | [.status, .timefrom, .timeto] | @tsv' |
while read -r status from to; do
    printf '"%s","%s","%s","%s"\n' "$status" "$((to - from))" "$(date -d @"$from")" "$(date -d @"$to")"
done |
if [ -n "${TSV:-}" ]; then
    column -t -s , |
    sed 's/"//g'
else
    cat
fi
