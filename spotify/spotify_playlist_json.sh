#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
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
Returns Spotify API output for a given playlist

Playlist argument can be a playlist name or ID (see spotify_playlists.sh)

Caveat: limited to 50 public playlists due to Spotify API, must specify OFFSET=50 to get next 50.
        This script does not iterate each page automatically because the output would be nonsensical
        multiple json outputs so you must iterate yourself and process each json result in turn
        For an example of how to do this and process multiple paged requests see spotify_playlist_tracks.sh

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
    usage "playlist id not defined"
fi

spotify_token

playlist_id="$("$srcdir/spotify_playlist_name_to_id.sh" "$playlist_id" "$@")"

# defined in lib/spotify.sh
# shellcheck disable=SC2154
"$srcdir/spotify_api.sh" "/v1/playlists/$playlist_id?limit=$limit&offset=$offset" "$@"
