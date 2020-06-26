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
usage_args="<playlist_id> [<curl_options>]"

# shellcheck disable=SC2034
usage_description="
Returns spotify playlist for given playlist id argument or \$SPOTIFY_PLAYLIST (get this from spotify_playlists.sh)

Requires \$SPOTIFY_CLIENT_ID and \$SPOTIFY_CLIENT_SECRET to be defined in the environment

Caveat: limited to 50 public playlists due to Spotify API, must specify OFFSET=50 to get next 50. This script does not iterate each page automatically because the output would be nonsensical multiple json outputs so you must iterate yourself and process each json result in turn

For an example of how to do this and process multiple paged requests see spotify_playlist_tracks.sh
"

# shellcheck disable=SC1090
. "$srcdir/lib/utils.sh"

help_usage "$@"

playlist_id="${1:-${SPOTIFY_PLAYLIST:-}}"

if [ -z "$playlist_id" ]; then
    usage "playlist id not defined"
fi

offset="${OFFSET:-0}"

if [ -z "${SPOTIFY_ACCESS_TOKEN:-}" ]; then
    export SPOTIFY_ACCESS_TOKEN="$("$srcdir/spotify_api_token.sh")"
fi

"$srcdir/spotify_api.sh" "/v1/playlists/$playlist_id?limit=50&offset=$offset" "$@"
