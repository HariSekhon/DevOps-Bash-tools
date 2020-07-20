#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  args: 64OO67Be8wOXn6STqHxexr
#
#  Author: Hari Sekhon
#  Date: 2020-06-24 01:17:21 +0100 (Wed, 24 Jun 2020)
#
#  https://github.com/harisekhon/bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/harisekhon
#

# https://developer.spotify.com/documentation/web-api/reference/playlists/get-playlist/

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck disable=SC1090
. "$srcdir/lib/spotify.sh"

# shellcheck disable=SC2034
usage_description="
Returns track URIs for the given Spotify public playlist

Playlist argument can be a playlist name (a regex which will return the first matching playlist)
or a playlist ID (get this from spotify_playlists.sh)

\$SPOTIFY_PLAYLIST can be used from environment if no first argument is given

Spotify track URIs can be used:
- as backups to restore a playlist's contents
- copied to new playlists
- set to Liked (spotify_set_track_uris_to_liked.sh)

$usage_auth_msg

Caveat: due to limitations of the Spotify API, this by default only works for public playlists. For private playlists you must get an interactively authorized access token like so:

export SPOTIFY_ACCESS_TOKEN=\"\$(\"$srcdir/spotify_api_token_interactive.sh\")\"
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<playlist_id> [<curl_options>]"

help_usage "$@"

playlist_id="${1:-${SPOTIFY_PLAYLIST:-}}"

shift || :

if [ -z "$playlist_id" ]; then
    usage "playlist id not defined"
fi

spotify_token

playlist_id="$("$srcdir/spotify_playlist_name_to_id.sh" "$playlist_id" "$@")"

# $limit/$offset defined in lib/spotify.sh
# shellcheck disable=SC2154
url_path="/v1/playlists/$playlist_id/tracks?limit=$limit&offset=$offset"

output(){
    #jq -r '.' <<< "$output"
    jq -r '.items[] | select(.track.uri) | [.track.uri] | @tsv' <<< "$output"
}

while has_next_url; do
    output="$("$srcdir/spotify_api.sh" "$url_path" "$@")"
    exit_if_jq_error
    url_path="$(get_next)"
    output
done
