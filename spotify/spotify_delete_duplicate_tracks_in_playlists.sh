#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  args: test
#
#  Author: Hari Sekhon
#  Date: 2020-07-24 19:05:25 +0100 (Fri, 24 Jul 2020)
#
#  https://github.com/HariSekhon/Spotify-Playlists
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
. "$srcdir/lib/spotify.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Deletes duplicate Spotify tracks in a given playlist (by Artist - Track name match, may be from different albums / singles and not 100% identical performances)

Playlist must be specified as the first argument and can be either a Spotify playlist ID or a full playlist name (see spotify_playlists.sh)

$usage_playlist_help

$usage_auth_help
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<playlist_name_or_id>"

help_usage "$@"

min_args 1 "$@"

playlist="$1"
shift || :

# requires authorized token
export SPOTIFY_PRIVATE=1

spotify_token

# this script returns the ID if it's already in the correct format, otherwise queries and returns the playlist ID for the playlist
playlist_id="$(SPOTIFY_PLAYLIST_EXACT_MATCH=1 "$srcdir/spotify_playlist_name_to_id.sh" "$playlist")"

export SPOTIFY_DUPLICATE_TRACK_POSITIONS=1

timestamp "Finding and deleting duplicate tracks in playlist \"$playlist\" by exact \"Artist - Track\" name match:"
duplicates="$("$srcdir/spotify_duplicate_tracks_in_playlist.sh" "$playlist_id")"

if [ -z "$duplicates" ]; then
    timestamp "No duplicate track names found"
    exit 0
fi

count="$(wc -l <<< "$duplicates" | sed 's/[[:space:]]*//g')"

if [ -z "${SPOTIFY_NO_CONFIRM:-}" ]; then
    if is_interactive; then
        timestamp "Duplicates to remove:"
        echo >&2

        while read -r position uri; do
            printf '%s\t' "$position"
            "$srcdir/spotify_uri_to_name.sh" <<< "$uri"
        done <<< "$duplicates"
        echo

        read -r -p "Are you sure you want to delete these $count tracks from playlist \"$playlist\"? (y/N) " answer
        echo >&2

        shopt -s nocasematch

        if ! [[ "$answer" =~ y|yes ]]; then
            timestamp "Aborting..."
            exit 1
        fi
    fi
fi

timestamp "Deleting $count duplicate tracks"
echo >&2
"$srcdir/spotify_delete_from_playlist.sh" "$playlist_id" <<< "$duplicates"
