#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-01-02 16:19:20 +0000 (Thu, 02 Jan 2020)
#
#  https://github.com/HariSekhon/DevOps-Bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/HariSekhon
#

# Script to fetch Cloudera Navigator Audit logs via API
#
# See cloudera_navigator_api.sh for base options like Navigator Host, SSL etc
#
# I've managed to crash Navigator several times both via the API and the UI trying to get access to > 1 years of historical logs
# even after increasing the heap by several GB, so I don't recommend you run more than one of these scripts at a time, and
# try to time bound it to a 1 year interval each time so it is more likely to succeed and less range to restart. I've written an
# adjacent script called cloudera_navigator_audit_download_logs.sh to manage iterating years and retrying where needed
#
# Tested on Cloudera Enterprise 5.10


# See the inline documentation for Cloudera Navigator Query filters
#
# https://$CLOUDERA_NAVIGATOR_HOST:7187/api-console/index.html#!/audits/getAudits
#
# https://$CLOUDERA_NAVIGATOR_HOST:7187/api-console/tutorial.html

# Usage:
#
#   ./cloudera_navigator_audit_logs.sh <start_date> <end_date> <query_filter> <curl_options> ...

# Examples:
#
# All logs up to now:
#
#   ./cloudera_navigator_audit_logs.sh <query> ... > navigator_audit_log.csv
#
#
# Last year of Impala queries (literally today minus 1 year right down to the second):
#
#   ./cloudera_navigator_audit_logs.sh "1 year ago" service==impala ... > navigator_audit_log_year.csv
#
#
# All Privilege Grants up to now:
#
#   ./cloudera_navigator_audit_logs.sh command==GRANT_PRIVILEGE > navigator_audit_log_grants.csv
#
#   ./cloudera_navigator_audit_logs.sh command==REVOKE_PRIVILEGE > navigator_audit_log_revokes.csv
#
#
# From Start to End Dates, all hive queries in 2019:
#
#   ./cloudera_navigator_audit_logs.sh "2019-01-01T00:00:00" "2020-01-01T00:00:00" service==hive ... > navigator_audit_log_hive_2019.csv
#
#
# All logs up to now for the Impala service, ignoring the self-signed certificate:
#
#   ./cloudera_navigator_audit_logs.sh service==impala -k > navigator_audit_log_impala.csv
#
#
# Since this can easily take an hour or two per year of logs to download, you may want to add progress dots like so:
#
#   ./cloudera_navigator_audit_logs.sh service==impala -k | ../bin/progress_dots.sh > navigator_audit_log_impala.csv
#
#
# or if you want full curl interactive progress on stderr:
#
#   PROGRESS=1 ./cloudera_navigator_audit_logs.sh service==impala -k > navigator_audit_log_impala.csv
#
#
# XXX: looks like there is a bug in the Navigator API returning only admin commands, not data access, for when start date set to 1970-01-01T00:00:00 - workaround is to use 1970-01-01T00:00:01

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
    #start="1 year ago"
    # XXX: this causes Navigator API to return only admin commands and not SQL queries... weird
    #start="1970-01-01T00:00:00"
    # looks like a bug, workaround:
    start="1970-01-01T00:00:01"
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
echo "fetching audit logs from  '$start_date'  to  '$end_date'" >&2

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
