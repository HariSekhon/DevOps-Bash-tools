#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2025-11-01 23:39:41 +0300 (Sat, 01 Nov 2025)
#
#  https///github.com/HariSekhon/DevOps-Bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn
#  and optionally send me feedback to help steer this or other code I publish
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
Queries the local Mac's Shazam app sqlite database and outputs all tracks, one per line
in format:

Artist - Track

Useful for using in conjunction with the adjacent spotify_app_search.sh script
since Apple removed Shazam's Spotify integration

Can optionally specify a number of tracks to stop after as an arg or environment variable \$SHAZAM_APP_DUMP_NUM_TRACKS

Tested on Shazam app version 2.11.0 - may need to be modified for other versions as the Shazam DB schema changes
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<num_tracks|today|yesterday|week|last:num_days|YYYY-MM-DD>]"

help_usage "$@"

max_args 1 "$@"

mac_only

arg="${1:-${SHAZAM_APP_DUMP_NUM_TRACKS:--1}}"

dbpath="$(
    find ~/Library/Group\ Containers \
        -type f \
        -path '*/*.group.com.shazam/com.shazam.mac.Shazam/ShazamDataModel.sqlite' \
        2>/dev/null |
    head -n 1
)"

if [ -z "$dbpath" ]; then
    die "Error: Could not locate ShazamDataModel.sqlite"
fi

timestamp "Found Shazam App DB: $dbpath"

where_clause=""
order_clause="ORDER BY r.ZDATE DESC"
limit_clause=""

# macOS Core Data framework stores dates as seconds 2001-01-01 00:00:00 UTC, not unix epoch of 1970
coredata_epoch_offset=978307200

# XXX: localtime strftime() may give off comparisons vs UTC stored date timestamps, so avoided for YYYY-MM-DD
#      keeping local day for today/yesterday/week or last:N though
case "$arg" in
    today)
        where_clause="
            WHERE
                r.ZDATE >= (
                    strftime('%s', 'now', 'start of day', 'localtime') - $coredata_epoch_offset
                )
        "
        order_clause="ORDER BY r.ZDATE ASC"
        ;;
    yesterday)
        where_clause="
            WHERE
                r.ZDATE >= (
                    strftime('%s', 'now', 'start of day', '-1 day', 'localtime') - $coredata_epoch_offset
                )
            AND
                r.ZDATE < (
                    strftime('%s', 'now', 'start of day', 'localtime') - $coredata_epoch_offset
                )
        "
        order_clause="ORDER BY r.ZDATE ASC"
        ;;
    week)
        where_clause="
            WHERE
                r.ZDATE >= (
                    strftime('%s', 'now', 'start of day', '-6 days', 'localtime')
                    - $coredata_epoch_offset
                )
        "
        order_clause="ORDER BY r.ZDATE ASC"
        ;;
    last:*)
        days="${arg#last:}"

        if ! [[ "$days" =~ ^[[:digit:]]+$ ]]; then
            die "Invalid argument for last:N, must be a positive integer: $arg"
        fi

        where_clause="
            WHERE
                r.ZDATE >= (
                    strftime('%s', 'now', '-$days days', 'localtime')
                    - $coredata_epoch_offset
                )
        "
        order_clause="ORDER BY r.ZDATE ASC"
        ;;
    ????-??-??)
        where_clause="
            WHERE
                r.ZDATE >= (
                    strftime('%s', '$arg', 'start of day')
                    - $coredata_epoch_offset
                )
            AND
                r.ZDATE < (
                    strftime('%s', '$arg', 'start of day', '+1 day')
                    - $coredata_epoch_offset
                )
        "
        order_clause="ORDER BY r.ZDATE ASC"
        ;;
    *)
        num="$arg"

        if ! [[ "$num" =~ ^-?[[:digit:]]+$ ]]; then
            die "Invalid argument given, must be an integer, 'today', or 'yesterday': $arg"
        fi

        if [ "$num" -gt 0 ]; then
            limit_clause="LIMIT $num"
        fi
        ;;
esac
# my ~/.sqliterc forces pretty printing breaking the separator we need so -init /dev/null to ignore it
sqlite3 "$dbpath" -init /dev/null -noheader -separator $'\t' \
"
    SELECT
        a.ZNAME AS artist,
        r.ZTRACKNAME AS track
    FROM
        ZSHTAGRESULTMO r
    LEFT JOIN
        ZSHARTISTMO a
            ON
        a.ZTAGRESULT = r.Z_PK
    $where_clause
    $order_clause
    $limit_clause;
" |
sed '/^[[:space:]]*$/d' |
while IFS=$'\t' read -r artist title; do
    # trim leading/trailing whitespace and replace newlines
    artist="$(tr -d '\r' <<< "$artist" | sed 's/^ *//;s/ *$//')"
    title="$(tr -d '\r' <<< "$title" | sed 's/^ *//;s/ *$//')"
    printf "%s\t-\t%s\n" "$artist" "$title"
done |
# from https://github.com/HariSekhon/DevOps-Perl-tools repo - use it if present in $PATH
if type -P uniq_order_preserved.pl &>/dev/null; then
    uniq_order_preserved.pl
else
    cat
fi
