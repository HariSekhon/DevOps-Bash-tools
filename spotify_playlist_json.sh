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

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<playlist> [<curl_options>]"

# shellcheck disable=SC2034
usage_description="
Returns Spotify API output for a given public playlist

Playlist argument can be a playlist name (a regex which will return the first matching playlist)
or a playlist ID (get this from spotify_playlists.sh)

\$SPOTIFY_PLAYLIST can be used from environment if no first argument is given

Requires \$SPOTIFY_CLIENT_ID and \$SPOTIFY_CLIENT_SECRET to be defined in the environment

Caveat: limited to 50 public playlists due to Spotify API, must specify OFFSET=50 to get next 50.
        This script does not iterate each page automatically because the output would be nonsensical
        multiple json outputs so you must iterate yourself and process each json result in turn
        For an example of how to do this and process multiple paged requests see spotify_playlist_tracks.sh

Caveat: due to limitations of the Spotify API, this only works for public playlists
"

# shellcheck disable=SC1090
. "$srcdir/lib/utils.sh"

help_usage "$@"

playlist_id="${1:-${SPOTIFY_PLAYLIST:-}}"

shift || :

if [ -z "$playlist_id" ]; then
    usage "playlist id not defined"
fi

playlist_id="$("$srcdir/spotify_playlist_name_to_id.sh" "$playlist_id" "$@")"

offset="${OFFSET:-0}"

if [ -z "${SPOTIFY_ACCESS_TOKEN:-}" ]; then
    SPOTIFY_ACCESS_TOKEN="$("$srcdir/spotify_api_token.sh")"
    export SPOTIFY_ACCESS_TOKEN
fi

"$srcdir/spotify_api.sh" "/v1/playlists/$playlist_id?limit=50&offset=$offset" "$@"
