#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-08-24 13:10:46 +0100 (Mon, 24 Aug 2020)
#
#  https://github.com/HariSekhon/DevOps-Bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/HariSekhon
#

# https://docs.pingdom.com/api/

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck disable=SC1090,SC1091
. "$srcdir/lib/utils.sh"

# shellcheck disable=SC1090,SC1091
. "$srcdir/lib/git.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Queries the Pingdom API (v3.1)

Can specify \$CURL_OPTS for options to pass to curl, or pass them as arguments to the script

Automatically handles authentication via environment variable \$PINGDOM_TOKEN


You must set up an access token here:

    https://my.pingdom.com/app/api-tokens


API Reference:

    https://docs.pingdom.com/api/


Examples:


# Get Pingdom checks and statuses:

    ${0##*/} /checks


# Get detailed info on a specific check:

    ${0##*/} /checks/<id>


# Get average uptime / response time for a specific check:

    ${0##*/} /summary.average/<check_id>


# Get Pingdom actions such as status change emails and SMS (newest first):

    ${0##*/} /actions


# Get your configured Maintenance windows and occurrences:

    ${0##*/} /maintenance
    ${0##*/} /maintenance.occurrences


# Recent Outages (last week by default, see pingdom_check_outages.sh for last year):

    ${0##*/} /summary.outage/<check_id>


# List all Pingdom probe servers

    ${0##*/} /probes


# Get check results from all probes for a given check id (find which geographies a sight is being affected in). You will need to correlate this to the probe ids from from the /probes query

    ${0##*/} /results/<check_id>


# List teams and their members:

    ${0##*/} /alerting/teams


# List alert contacts:

    ${0##*/} /alerting/contacts


# Get Credits remaining:

    ${0##*/} /credits
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="/path [<curl_options>]"

url_base="https://api.pingdom.com/api/3.1"

help_usage "$@"

min_args 1 "$@"

check_env_defined "PINGDOM_TOKEN"

#curl_api_opts json headers breaks the Pingdom API calls
if [ -n "${CURL_OPTS:-}" ]; then
    read -r -a CURL_OPTS <<< "${CURL_OPTS[@]}" # this @ notation works for both strings and arrays in case a future version of bash do export arrays this should still work
else
    CURL_OPTS=(-sS --fail --connect-timeout 3)
fi

url_path="$1"
shift || :

url_path="${url_path##/}"

export TOKEN="$PINGDOM_TOKEN"

"$srcdir/../bin/curl_auth.sh" "$url_base/$url_path" "${CURL_OPTS[@]}" "$@"

# args: /checks | jq .
# args: /checks/<check_id>
# args: /checks/$(pingdom_api.sh /checks | jq -r 'first(.checks[].id)') | jq .
# args: /alerting/contacts | jq .
# args: /alerting/teams | jq .
# args: /credits | jq .
# args: /actions | jq .
# args: /summary.average/<checkid>
# args: /summary.average/$(pingdom_api.sh /checks | jq -r 'first(.checks[].id)') | jq .
# args: /summary.outage/$(pingdom_api.sh /checks | jq -r 'first(.checks[].id)') | jq .
# args: /summary.hoursofday/$(pingdom_api.sh /checks | jq -r 'first(.checks[].id)') | jq .
# args: /summary.performance/$(pingdom_api.sh /checks | jq -r 'first(.checks[].id)') | jq .
# args: /maintenance | jq .
# args: /maintenance.occurrences | jq .
# args: /probes | jq .
# args: /analysis/<check_id> | jq .
# args: /analysis/$(pingdom_api.sh /checks | jq -r 'first(.checks[].id)') | jq .
