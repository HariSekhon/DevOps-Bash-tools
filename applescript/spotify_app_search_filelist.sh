#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2026-04-29 23:48:55 +0200 (Wed, 29 Apr 2026)
#
#  https///github.com/HariSekhon/DevOps-Bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn
#  and optionally send me feedback
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
Searches the local Spotify desktop app for each track in a given file

File format:

Artist   \\t Song
Artist 2 \\t Song 2
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="artist-tracks.txt"

help_usage "$@"

num_args 1 "$@"

filelist="$1"

if ! [ -f "$filelist" ]; then
    usage "No file given"
elif ! [ -s "$filelist" ]; then
    usage 'Given file is empty!'
elif is_blank "$("$srcdir/../bin/decomment.sh" "$filelist")"; then
    usage 'Given file is empty except for comments / whitespace!'
fi

while IFS=$'\t' read -r artist track; do
    "$srcdir/spotify_app_search.sh" "$artist $track"
    timestamp "Press enter to search for next track"
    read -r < /dev/tty
done < <(
    "$srcdir/../bin/decomment.sh" "$filelist"
)
