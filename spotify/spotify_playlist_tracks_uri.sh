#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  args: "Upbeat & Sexual Pop"
#  args: 64OO67Be8wOXn6STqHxexr
#
#  Author: Hari Sekhon
#  Date: 2020-06-24 01:17:21 +0100 (Wed, 24 Jun 2020)
#
#  https://github.com/HariSekhon/DevOps-Bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/HariSekhon
#

# https://developer.spotify.com/documentation/web-api/reference/playlists/get-playlist/

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck disable=SC1090,SC1091
. "$srcdir/lib/spotify.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Returns track URIs for the given Spotify playlist

Playlist argument can be a playlist name or ID (see spotify_playlists.sh)

\$SPOTIFY_PLAYLIST can be used from environment if no first argument is given

Spotify track URIs can be used:
- as backups to restore a playlist's contents
- copied to new playlists
- set to Liked (spotify_set_tracks_uri_to_liked.sh)

$usage_playlist_help

$usage_auth_help
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<playlist> [<curl_options>]"

help_usage "$@"

playlist_id="${1:-${SPOTIFY_PLAYLIST:-}}"

shift || :

if is_blank "$playlist_id"; then
    usage "playlist not defined"
fi

spotify_token

playlist_id="$("$srcdir/spotify_playlist_name_to_id.sh" "$playlist_id" "$@")"

# defined in lib/spotify.sh
# shellcheck disable=SC2154
url_path="/v1/playlists/$playlist_id/tracks?limit=100&offset=$offset"

output(){
    #jq -r '.' <<< "$output"

    # If you set \$SPOTIFY_PLAYLIST_TRACKS_UNAVAILABLE=1 then will only output tracks that are unavailable (greyed out on Spotify)
    # Can feed this in to spotify_delete_from_playlist.sh to crop them from TODO / Discover Backlog type playlists
    #if [ -n "${SPOTIFY_PLAYLIST_TRACKS_UNAVAILABLE:-}" ]; then
        # XXX: this isn't reliable, some tracks are still available when these fields are both empty :-/
        # and debug dumps comparing tracks shows there are no other fields to differentiate whether a track is available or not
    #    jq -r '.items[] | select(.track.uri) | select((.track.available_markets | length) == 0) | select((.track.album.available_markets | length) == 0)' <<< "$output"
    #else
    jq -r '.items[] | select(.track.uri) | .track.uri' <<< "$output"
    #fi
}

while not_null "$url_path"; do
    output="$("$srcdir/spotify_api.sh" "$url_path" "$@")"
    #die_if_error_field "$output"
    url_path="$(get_next "$output")"
    output
done
