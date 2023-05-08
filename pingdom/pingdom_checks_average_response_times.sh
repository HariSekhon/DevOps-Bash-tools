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

# https://docs.pingdom.com/api/#tag/Summary.average

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck disable=SC1090,SC1091
. "$srcdir/lib/utils.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Lists the average response times for all Pingdom checks over the last week via the Pingdom API

Output format - quoted CSV:

\"<id>\",\"<name>\",\"<type>\",\"<hostname>\",\"<status>\",\"<average_response_time_in_ms>\"

For TSV format, set TSV=1 environment variable. TSV output must wait until until the end after every check's query has returned, in order to get the column alignment correct


\$PINGDOM_TOKEN must be defined in the environment for authentication

See adjacent pingdom_api.sh for more details
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<curl_options>]"

help_usage "$@"

epoch_1_week_ago="$(date "+%s" -d "1 week ago")"

"$srcdir/pingdom_api.sh" /checks "$@" |
jq -r ".checks[] | [.id, .type, .hostname, .status, .name] | @tsv" |
while read -r id type hostname status name; do
    printf '"%s","%s","%s","%s","%s","%s"\n' "$id" "$name" "$type" "$hostname" "$status" \
    "$("$srcdir/pingdom_api.sh" "/summary.average/$id?from=$epoch_1_week_ago" "$@" | jq '.summary.responsetime.avgresponse')"
done |
if [ -n "${TSV:-}" ]; then
    column -t -s , |
    sed 's/"//g'
else
    cat
fi
