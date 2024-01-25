#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  args: "My Shazam tracks"
#
#  Author: Hari Sekhon
#  Date: 2020-07-23 23:26:15 +0100 (Thu, 23 Jul 2020)
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
Sets given Spotify playlists to public

Accepts Spotify playlist names or IDs as either arguments or on standard input, one playlist per line

$usage_auth_help
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<playlist_name_or_id> [<playlist2> <playlist3>]"

help_usage "$@"

# modifying a playlist requires an authorized token
export SPOTIFY_PRIVATE=1

spotify_token

set_playlist_public(){
    local playlist="$1"
    local playlist_id
    local playlist_name

    # this script returns the ID if it's already in the correct format, otherwise queries and returns the playlist ID for the playlist
    playlist_id="$(SPOTIFY_PLAYLIST_EXACT_MATCH=1 "$srcdir/spotify_playlist_name_to_id.sh" "$playlist")"

    playlist_name="$("$srcdir/spotify_playlist_id_to_name.sh" "$playlist_id")"

    url_path="/v1/playlists/$playlist_id"

    timestamp "setting playlist '$playlist_name' to public"
    "$srcdir/spotify_api.sh" "$url_path" -X PUT -H "Content-Type: application/json" -d "{ \"public\": true }"
}

if [ $# -gt 0 ]; then
    for playlist in "$@"; do
        set_playlist_public "$playlist"
    done
else
    while read -r playlist; do
        set_playlist_public "$playlist"
    done
fi
