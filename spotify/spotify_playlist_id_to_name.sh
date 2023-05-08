#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#  args: 2ddv4fdbsD7WOnmY30g40i | tee /dev/stderr | spotify_playlist_name_to_id.sh
#
#  Author: Hari Sekhon
#  Date: 2020-07-03 00:25:24 +0100 (Fri, 03 Jul 2020)
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
Uses Spotify API to translate a Spotify public playlist ID to a name

If a spotify playlist name is given instead of an ID, returns it as is

A single playlist ID can be given as an argument, or a list can be passed via stdin

Needed by several other adjacent spotify tools


$usage_playlist_help

$usage_auth_help

"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<playlist> [<curl_options>]"

help_usage "$@"

playlist_id_to_name(){
    local playlist_id="$1"
    shift || :
    # if it's not a playlist id, scan all playlists and take the ID of the first matching playlist name
    if is_spotify_playlist_id "$playlist_id"; then
        playlist_name="$("$srcdir/spotify_api.sh" "/v1/playlists/$playlist_id" "$@" |
                    jq -r '.name' || :)"
        # it turns out a playlist name can be blank :-/
        #if is_blank "$playlist_name" || [ "$playlist_name" = null ]; then
        if is_blank "$playlist_name"; then
            echo "$playlist_id"
        elif [ "$playlist_name" = null ]; then
            echo "Error: failed to find playlist name matching ID '$playlist_id'" >&2
            exit 1
        fi
        echo "$playlist_name"
    else
        echo "$playlist_id"
    fi
}

spotify_token

if [ $# -gt 0 ]; then
    playlist_id="$1"
    shift || :
    playlist_id_to_name "$playlist_id" "$@"
else
    while read -r playlist_id; do
        playlist_id_to_name "$playlist_id" "$@"
    done
fi
