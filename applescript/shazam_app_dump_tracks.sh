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

Tested on Shazam app version 2.11.0 - may need to be modified for other versions as the Shazam DB schema changes
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args=""

help_usage "$@"

no_args "$@"

mac_only

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

#table="ZSHTAGRESULTMO"

# detect columns dynamically
#cols="$(
#    sqlite3 "$dbpath" "PRAGMA table_info($table);" |
#    awk '{print $2}'
#)"

#artist_column="$(grep -m1 -E 'ARTIST' <<< "$cols" || :)"
#track_column="$(grep -m1 -E 'TRACK' <<< "$cols" || :)"
#date_column="$(grep -m1 -E 'DATE' <<< "$cols" || :)"

#[ -n "$artist_column" ] || die "Error: Failed to find artist column"
#[ -n "$track_column" ] || die "Error: Failed to find track column"
#[ -n "$date_column" ] || die "Error: Failed to find date column"

#timestamp "Found columns:
#
#$artist_column
#$track_column
#$date_column
#"

# my ~/.sqliterc forces pretty printing breaking the separator we need so -init /dev/null to ignore it
sqlite3 "$dbpath" -init /dev/null -noheader -separator $'\t' \
"
    SELECT a.ZNAME AS artist, r.ZTRACKNAME AS track
        FROM ZSHTAGRESULTMO r
        LEFT JOIN ZSHARTISTMO a ON a.ZTAGRESULT = r.Z_PK
        ORDER BY r.ZDATE DESC;
" |
sed '/^[[:space:]]*$/d' |
while IFS=$'\t' read -r artist title; do
    # trim leading/trailing whitespace and replace newlines
    artist="$(tr -d '\r' <<< "$artist" | sed 's/^ *//;s/ *$//')"
    title="$(tr -d '\r' <<< "$title" | sed 's/^ *//;s/ *$//')"
    printf "%s\t-\t%s\n" "$artist" "$title"
done
