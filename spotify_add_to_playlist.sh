#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-07-23 18:02:26 +0100 (Thu, 23 Jul 2020)
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
Adds Spotify URIs to a given playlist

Playlist must be specified as the first argument and can be either a Spotify playlist ID or a full playlist name (see spotify_playlists.sh)

Can take file(s) with URIs as arguments or read from standard input for chaining with other tools

Useful for chaining with other 'spotify_*_uri.sh' tools (eg. spotify_playlist_tracks_uri.sh, spotify_search_uri.sh) or loading from saved spotify format playlists (eg. HariSekhon/Spotify-Playlists github repo)

$usage_playlist_help

$usage_auth_help
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<playlist_name_or_id> [<file1> <file2> ...]"

help_usage "$@"

min_args 1 "$@"

playlist="$1"
shift || :

# requires authorized token
export SPOTIFY_PRIVATE=1

spotify_token

# this script returns the ID if it's already in the correct format, otherwise queries and returns the playlist ID for the playlist
playlist_id="$(SPOTIFY_PLAYLIST_EXACT_MATCH=1 "$srcdir/spotify_playlist_name_to_id.sh" "$playlist")"

playlist_name="$("$srcdir/spotify_playlist_id_to_name.sh" "$playlist_id")"

# playlist ID obtained from 'spotify_playlists.sh'
url_path="/v1/playlists/$playlist_id/tracks"

count=0

add_to_playlist(){
    if [ $# -lt 1 ]; then
        echo "Error: no IDs passed to add_to_playlist()" >&2
        exit 1
    fi
    local id_array=""
    for id in "$@"; do
        # requires explicit track URI type since could also be episodes added to playlist
        id_array+="\"spotify:track:$id\", "
    done
    id_array="${id_array%, }"
    timestamp "adding ${#@} tracks to playlist '$playlist_name'"
    "$srcdir/spotify_api.sh" "$url_path" -X POST -d '{"uris": '"[$id_array]}" >/dev/null  # ignore the { "spotify_snapshot": ... } json output
    ((count+=${#@}))
}

add_file_URIs(){
    declare -a ids
    ids=()
    while read -r track_uri; do
        if is_blank "$track_uri"; then
            continue
        fi
        if is_local_uri "$track_uri"; then
            continue
        fi
        id="$(validate_spotify_uri "$track_uri")"

        ids+=("$id")

        if [ "${#ids[@]}" -ge 50 ]; then
            add_to_playlist "${ids[@]}"
            sleep 1
            ids=()
        fi
    done < "$filename"

    if [ "${#ids[@]}" -eq 0 ]; then
        return
    fi
    add_to_playlist "${ids[@]}"
}

for filename in "${@:-/dev/stdin}"; do
    add_file_URIs "$filename"
done

timestamp "$count tracks added to playlist '$playlist_name'"
