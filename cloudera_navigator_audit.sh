#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-01-02 16:19:20 +0000 (Thu, 02 Jan 2020)
#
#  https://github.com/harisekhon/bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/harisekhon
#

# Script to fetch Cloudera Navigator Audit logs via API
#
# See cloudera_navigator_api.sh for base options like Navigator Host, SSL etc
#
# From 1 year ago to Now (this is literally today minus 1 year right down to the second)
#
# ./cloudera_navigator_audit.sh "1 year ago" <query_filter> <curl_options> ...


# See the inline documentation for Cloudera Navigator Query filters
#
# https://$CLOUDERA_NAVIGATOR_HOST:7187/api-console/index.html#!/audits/getAudits
#
# https://$CLOUDERA_NAVIGATOR_HOST:7187/api-console/tutorial.html

# Examples:
#
# All logs up to now:
#
# ./cloudera_navigator_audit.sh <query> ...
#
#
# From Start to End Dates:
#
# ./cloudera_navigator_audit.sh "2019-01-01T00:00:00" "2020-01-01T00:00:00" <query> ...
#
#
# All logs up to now for the Impala service, ignoring the self-signed certificate:
#
# ./cloudera_navigator_audit.sh service==impala -k
#
#
# combine with jq commands to extract the info you want from the json output
#
# ./cloudera_navigator_audit.sh impala | jq -r '.queries[].statement'

# Tested on Cloudera Enterprise 5.10

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=lib/cloudera_navigator.sh
. "$srcdir/lib/utils.sh"

# shellcheck source=lib/cloudera_navigator.sh
. "$srcdir/lib/cloudera_navigator.sh"

# to use Linux's date -d switch
if is_mac; then
    date="gdate"
else
    date="date"
fi

start=""
end=""

if [[ "${1:-}" =~ ^[[:digit:]] ]]; then
    start="$1"
    shift
fi

if [[ "${1:-}" =~ ^[[:digit:]] ]]; then
    end="$1"
    shift
fi

if [ -z "$start" ]; then
    start="1970-01-01T00:00:00"
fi
start_epoch_ms="$("$date" --utc -d "$start" +%s000)"

if [ -z "$end" ]; then
    end_epoch_ms="$now_timestamp"
else
    end_epoch_ms="$("$date" --utc -d "$end" +%s000)"
fi

start_date="$($date --utc -d "@${start_epoch_ms%000}")"
end_date="$($date --utc -d "@${end_epoch_ms%000}")"

# defined in lib
# shellcheck disable=SC2154
echo "fetching audit logs from '$start_date' to '$end_date'" >&2

query=""
if ! [[ "${1:-}" =~ ^- ]]; then
    query="${1:-}"
    shift
fi

# don't page through this, dump as whole attachment
limit="${limit:-10000}" # max limit
offset="${offset:-0}"

# CSV format seems to default to attachment=true, ignoring limits and offsets, even when attachment=false

# default in API is JSON
#format="${format:-JSON}"  # or CSV
format=CSV  # only way to get all the records

# attachment will ignore default 10,000 limit and return all results which is what we want - seems to not work on JSON, use CSV format instead, which also seems to ignore limit & offset even with attachment=false
#"$srcdir/cloudera_navigator_api.sh" "/audits/?query=${query}&startTime=${start_epoch_ms}&endTime=${end_epoch_ms}&format=${format}&limit=$limit&offset=$offset&attachment=false" "$@"
"$srcdir/cloudera_navigator_api.sh" "/audits/?query=${query}&startTime=${start_epoch_ms}&endTime=${end_epoch_ms}&format=${format}&attachment=true" "$@"
