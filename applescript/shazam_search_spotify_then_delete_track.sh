#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2025-11-02 00:30:16 +0300 (Sun, 02 Nov 2025)
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
Dumps the local Mac Shazam app's tracks one at a time, searches the Spotify app for each one,
and then deletes it from the Shazam local sqlite DB upon an Enter key press to proceed to the next one

Shazam to Spotify apps workaround to Apple removing Spotify integration from Shazam

Can optionally specify a number of tracks to stop after as an arg or environment variable \$SHAZAM_APP_DUMP_NUM_TRACKS
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<num_tracks>]"

help_usage "$@"

max_args 1 "$@"

mac_only

num="${1:-${SHAZAM_APP_DUMP_NUM_TRACKS:-1}}"

if ! [[ "$num" =~ ^-?[[:digit:]]+$ ]]; then
    die "Invalid argument given, must be an integer: $num"
fi

relaunch_shazam(){
    timestamp "Relaunching Shazam app to reflect removed tracks"
    "$srcdir/reopen_app.sh" Shazam
    sleep 2
    # hit Escape key to to minimize Shazam back to the menu bar
    osascript -e "tell application \"System Events\" to key code 53"
    untrap
    exit
}
export -f relaunch_shazam

trap_cmd 'relaunch_shazam'

while IFS=$'\t' read -r artist _ track; do
    "$srcdir/spotify_app_search.sh" "$artist $track"
    timestamp "Press enter to delete this track from the Shazam DB: $artist - $track"
    read -r < /dev/tty
    "$srcdir/shazam_app_delete_track.sh" "$artist" "$track"
done < <(
    "$srcdir/shazam_app_dump_tracks.sh" "$num"
)
