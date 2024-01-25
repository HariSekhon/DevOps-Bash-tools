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
Deletes duplicate Spotify URIs in a given playlist

Playlist must be specified as the first argument and can be either a Spotify playlist ID or a full playlist name (see spotify_playlists.sh)

To see which URIs would be deleted, you can first run spotify_duplicate_uri_in_playlist.sh <playlist_name_or_id> and optionally pipe that through spotify_uri_to_name.sh to translate to human readable names eg for a playlist called 'test':

spotify_duplicate_uri_in_playlist.sh MyPlaylist

spotify_duplicate_uri_in_playlist.sh MyPlaylist | spotify_uri_to_name.sh

$usage_playlist_help

$usage_auth_help
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<playlist_name_or_id> [<playlist2> <playlist3> ...]"

help_usage "$@"

min_args 1 "$@"

# requires authorized token
export SPOTIFY_PRIVATE=1

spotify_token

export SPOTIFY_DUPLICATE_TRACK_POSITIONS=1

for playlist in "$@"; do
    # this script returns the ID if it's already in the correct format, otherwise queries and returns the playlist ID for the playlist
    playlist_id="$(SPOTIFY_PLAYLIST_EXACT_MATCH=1 "$srcdir/spotify_playlist_name_to_id.sh" "$playlist")"

    timestamp "Finding and deleting duplicates in playlist \"$playlist\" by exact URI match:"
    "$srcdir/spotify_duplicate_uri_in_playlist.sh" "$playlist_id" |
    "$srcdir/spotify_delete_from_playlist.sh" "$playlist_id"
done
