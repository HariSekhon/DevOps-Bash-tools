#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-03-06 12:03:19 +0000 (Fri, 06 Mar 2020)
#
#  https://github.com/HariSekhon/DevOps-Bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/HariSekhon
#

# Script to download all historical audit logs from Cloudera Navigator from 2009 to present
#
# 2009 was Cloudera's founding year so we don't search for history past that since it can never exist
#
# Uses adjacent cloudera_manager_audit.sh, see comments there for more details
#
# Tested on Cloudera Enterprise 5.10

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck disable=SC1090,SC1091
source "$srcdir/lib/utils.sh"

trap 'tstamp ERROR' exit

services="
hive
impala
hdfs
hbase
scm
"

# slighty better compression but takes forever, even slow to decompress
#compress_cmd="bzip2 -9 -c"
#compress_cmd="gzip -9 -c"
#ext="gz"

if [[ "${1:-}" =~ ^service== ]]; then
    single_service="${1##service==}"
    shift
fi

download_audit_logs(){
    local year="$1"
    local month="${2#0}"  # because maths ops + 1 won't work on zero prefixed string, so re-add it later
    local service="$3"
    shift; shift; shift
    if [ "${#month}" = 1 ]; then
        month="0$month"
    fi
    local log="navigator_audit_${year}-${month}_${service}.csv"
    local log_bytes
    # expand now
    # shellcheck disable=SC2064
    trap "tstamp ERROR; tstamp 'Removing partial log file for restartability without audit gaps: '; rm -fv -- '$log'" exit
    if validate_log "$log"; then
        tstamp "Skipping previously completed log $log..."
        echo >&2
        return
    else
        tstamp "Querying Cloudera Navigator for $year logs for $service"
        month="${month#0}"  # because maths ops + 1 won't work on zero prefixed string, so re-add it later
        if [ "$month" = 12 ]; then
            ((end_year=year+1))
            end_month=01
        else
            ((end_month=month+1))
            end_year="$year"
        fi
        if [ "${#month}" = 1 ]; then
            month="0$month"
        fi
        if [ "${#end_month}" = 1 ]; then
            end_month="0$end_month"
        fi
        # won't output a newline so the contents of next command will be timestamp prefixed
        tstamp
        #time {
        # don't let a random 401 stop from downloading other logs, can go back and fill in the gaps later by re-running
        # Navigator returns zero byte logs without headers without error so this || : is not the cause of not catching zero byte logs, which we have to check for separately anyway
        "$srcdir/cloudera_navigator_audit_logs.sh" "$year-$month-01T00:00:00" "$end_year-$end_month-01T00:00:00" "service==$service" "$@" | "$srcdir/../bin/progress_dots.sh" > "$log" || :
        log_bytes="$(stat_bytes "$log")"
        tstamp "$log = $log_bytes bytes"
        if [ "$log_bytes" = 0 ]; then
            tstamp "ERROR: Navigator returned zero byte audit log for $log, not even containing the headers row!"
            return
        fi
        #}
    fi
    #local compressed_log="$log.$ext"
    #if [ -s "$log" ]; then
    if validate_log "$log"; then
        #tstamp "Compressing audit log:  $log > $compressed_log"
        # want splitting
        # shellcheck disable=SC2086
        #$compress_cmd "$log" > "$compressed_log" &
        :
    else
        tstamp "WARNING: $log doesn't look complete, must check"
    fi
    echo >&2
}

validate_log(){
    local log="$1"
    # a single newline in the log file trips this so dive in to deeper checks to make sure we have what looks like enough data
    if [ -s "$log" ]; then
        local log_bytes
        log_bytes="$(stat_bytes "$log")"
        tstamp "$log = $log_bytes bytes"
        if [ "$log_bytes" = 558 ]; then
            tstamp "$log has only headers - inferring there are no logs for that date range"
            return 0
        #elif [ "$log_bytes" -gt 10240 ]; then
        #    tstamp "Skipping $log since it already exists and is > 10MB"
        #    return 0
        #fi
        # audit logs start at $year-12-* at the top, and end at the bottom in $year-01-* - partial logs often get cut off
        # in between, so if we've gotten all the way to January the log is likely complete - tempted to do January 01 but
        # there will probably be some edge case where a service isn't used on New Year's day or the first few days
        # because a lot of people take time off around then, so this is more generic to just check for January
        # can't check for December also being in the log because this would always fail for the current year
        elif grep -q "^\"$year-$month-0" "$log"; then
            tstamp "$log contains logs for $year-$month-0*, looks complete"
            return 0
        fi
    fi
    return 1
}

current_year="$(date +%Y)"
current_month="$(date +%m)"

# works on Mac but seq on Linux doesn't do reverse, outputs nothing
#for year in $(seq "$current_year" 2009); do

# On Mac tac requires gnu coreutils to be installed via Homebrew
for year in $(seq 2009 "$current_year" | tac); do
    for month in {12..1}; do
        if [ "$year" -eq "$current_year" ] && [ "$month" -gt "$current_month" ]; then
            # Navigator returns forbidden if querying in the future
            continue
        fi
        if [ -n "${single_service:-}" ]; then
            download_audit_logs "$year" "$month" "$single_service" "$@"
        else
            for service in $services; do
                download_audit_logs "$year" "$month" "$service" "$@"
            done
        fi
    done
done
tstamp "Finished querying Cloudera Navigator API"
tstamp "Waiting for log compression to finish"
wait
tstamp "DONE"
trap - exit
