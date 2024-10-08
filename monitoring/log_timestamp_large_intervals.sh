#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2024-05-20 12:48:08 +0400 (Mon, 20 May 2024)
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
. "$srcdir/lib/utils.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Finds log lines whose timestamp intervals exceed the given number of seconds (default: 30)
and outputs those log lines with the difference between the last and current timestamps

Useful to find actions that are taking a long time from log files such as CI/CD logs

Expects each log line in the file to be prefixed with the following format:

YYYY-MM-DDTHH:MM:SS

(year month day T hour minute second)

This is a fairly standard log timestamp used by tools like Azure DevOps Pipeline logs
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<logfile> [<minimum_gap_seconds>]"

help_usage "$@"

#min_args 1 "$@"

logfile="${1:-/dev/stdin}"
minimum_secs_gap="${2:-30}"

# prefix format - must match the line strip inside the while loop below
#format="%Y-%M-%DT%H:%M:%S"

last_epoch=0
current_epoch=0
last_line=""

while read -r line; do
    # XXX: adjust this for other timestamp formats / lengths
    timestamp="${line:0:19}"  # must match the timestamp prefix length
    #timestamp="$(awk '{print $1}' <<< "$line")"  # needlessly expensive on forks and awk
    #timestamp="${line%%[[:space:]]*}"  # cheaper, take only the first token, but timestamps can have no spaces in them in place of the T separator
    current_epoch="$(date -d "$timestamp" +"%s")"

    if [[ "$last_epoch" -eq 0 ]]; then
        last_epoch="$current_epoch";
    fi

    gap_secs="$((current_epoch - last_epoch))"

    if [[ "$gap_secs" -gt "$minimum_secs_gap" ]]; then
        # redundant information, use for debugging only
        #echo "$gap_secs secs = $(date -d "@$last_epoch" +"$format") => $(date -d "@$current_epoch" +"$format")"
        #echo "$gap_secs secs"
        #if [ "$gap_secs" -gt 60 ]; then
            mins="$((gap_secs / 60))"
            secs="$((gap_secs % 60))"
            echo "$mins mins $secs secs"
        #fi
        echo "$last_line"
        echo "$line"
        echo
    fi

    last_epoch="$current_epoch"
    last_line="$line"
done < "$logfile"
