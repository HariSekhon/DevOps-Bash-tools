#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-03-06 12:03:19 +0000 (Fri, 06 Mar 2020)
#
#  https://github.com/harisekhon/bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/harisekhon
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

# shellcheck disable=SC1090
source "$srcdir/lib/utils.sh"

trap 'echo ERROR >&2' exit

services="
hive
impala
hdfs
hbase
scm
"

# slighty better compression but takes forever, even slow to decompress
#compress_cmd="bzip2 -9 -c"
compress_cmd="gzip -9 -c"
ext="gz"

current_year="$(date +%Y)"

if [[ "${1:-}" =~ ^service== ]]; then
    single_service="${1##service==}"
    shift
fi

download_audit_logs(){
    local year="$1"
    local service="$2"
    shift; shift
    local log="navigator_audit_${year}_${service}.csv"
    local log_bytes
    # expand now
    # shellcheck disable=SC2064
    trap "echo ERROR >&2; printf 'Removing partial log file for restartability without audit gaps: ' >&2; rm -fv '$log'" exit
    if validate_log "$log"; then
        echo "Skipping previously completed log $log..."
        echo
    else
        echo "Querying Cloudera Navigator for $year logs for $service"
        time {
        "$srcdir/cloudera_navigator_audit_logs.sh" "$year-01-01T00:00:00" "$((year+1))-01-01T00:00:00" "service==$service" "$@" | "$srcdir/progress_dots.sh" > "$log"
        log_bytes="$(stat_bytes "$log")"
        echo "$log = $log_bytes bytes"
        if [ "$log_bytes" = 0 ]; then
            echo "ERROR: Navigator return zero byte audit log for $log, not even containing the headers row!"
        fi
        }
    fi
    local compressed_log="$log.$ext"
    #if [ -s "$log" ]; then
    if validate_log "$log"; then
        echo "Compressing audit log:  $log > $compressed_log"
        # want splitting
        # shellcheck disable=SC2086
        $compress_cmd "$log" > "$compressed_log" &
    fi
    echo
}

validate_log(){
    local log="$1"
    # a single newline in the log file trips this so dive in to deeper checks to make sure we have what looks like enough data
    if [ -s "$log" ]; then
        local log_bytes
        log_bytes="$(stat_bytes "$log")"
        echo "$log = $log_bytes bytes"
        if [ "$log_bytes" = 558 ]; then
            echo "$log has only headers there are no logs for that date range"
            return 0
        #elif [ "$log_bytes" -gt 10240 ]; then
        #    echo "Skipping $log since it already exists and is > 10MB"
        #    return 0
        #fi
        # audit logs start at $year-12-* at the top, and end at the bottom in $year-01-* - partial logs often get cut off
        # in between, so if we've gotten all the way to January the log is likely complete - tempted to do January 01 but
        # there will probably be some edge case where a service isn't used on New Year's day or the first few days
        # because a lot of people take time off around then, so this is more generic to just check for January
        # can't check for December also being in the log because this would always fail for the current year
        elif grep -q "^\"$year-01-" "$log"; then
            echo "$log contains logs going back to January $year so looks complete"
            return 0
        fi
    fi
    return 1
}

# works on Mac but seq on Linux doesn't do reverse, outputs nothing
#for year in $(seq "$current_year" 2009); do

# On Mac tac requires gnu coreutils to be installed via Homebrew
for year in $(seq 2009 "$current_year" | tac); do
    if [ -n "${single_service:-}" ]; then
        download_audit_logs "$year" "$single_service" "$@"
    else
        for service in $services; do
            download_audit_logs "$year" "$service" "$@"
        done
    fi
done
echo "Finished querying Cloudera Navigator API"
echo "Waiting for log compression to finish"
wait
echo "DONE"
trap - exit
