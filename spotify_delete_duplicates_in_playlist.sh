#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  args: test
#
#  Author: Hari Sekhon
#  Date: 2020-07-24 19:05:25 +0100 (Fri, 24 Jul 2020)
#
#  https://github.com/harisekhon/spotify-playlists
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/harisekhon
#

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck disable=SC1090
. "$srcdir/lib/spotify.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Deletes duplicate Spotify URIs in a given playlist

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

count=0

# playlists max out at only around ~8000 tracks so this is safe to do in ram
tracklist_URIs="$("$srcdir/spotify_playlist_tracks_uri.sh" "$playlist_id")"

duplicate_URIs="$(sort <<< "$tracklist_URIs" | uniq -d)"

duplicate_URIs_with_track_positions="$(
while read -r uri; do
    ((count+=1))
    grep -Fxn "$uri" <<< "$tracklist_URIs" |
    tail -n +2
done <<< "$duplicate_URIs"
)"

"$srcdir/spotify_delete_from_playlist.sh" "$playlist_id" <<< "$duplicate_URIs_with_track_positions"
