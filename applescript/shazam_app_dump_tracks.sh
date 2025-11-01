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
Queries the local Mac's Shazam app sqlite database and outputs all tracks, one per line
in format:

Artist - Track

Useful for using in conjunction with the adjacent spotify_app_search.sh script
since Apple removed Shazam's Spotify integration
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

table="ZSHTAGRESULTMO"

# detect columns dynamically
cols="$(
    sqlite3 "$dbpath" "PRAGMA table_info($table);" |
    awk -F'|' '{print $2}'
)"

artist_column="$(grep -m1 -E 'ARTIST' <<< "$cols")"
title_column="$(grep -m1 -E 'TITLE' <<< "$cols")"
date_column="$(grep -m1 -E 'DATE' <<< "$cols")"

if [ -z "$artist_column" ] ||
   [ -z "$title_column" ] ||
   [ -z "$date_column" ]; then
    die "Error: Could not identify artist/title/date columns in table $table

Columns found:

$cols
"
fi

echo "Found columns:

$artist_column
$title_column
$date_column
"

sqlite3 "$dbpath" -noheader -separator $'\t' \
    "SELECT $artist_column, $title_column FROM $table ORDER BY $date_column DESC;" |
while IFS=$'\t' read -r artist title; do
    # trim leading/trailing whitespace and replace newlines
    artist="$(tr -d '\r' <<< "$artist" | sed 's/^ *//;s/ *$//')"
    title="$(tr -d '\r' <<< "$title" | sed 's/^ *//;s/ *$//')"
    echo "$artist - $title"
done
