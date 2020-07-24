#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
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
Deletes Spotify URIs from a given playlist

Playlist must be specified as the first argument and can be either a Spotify playlist ID or a full playlist name (see spotify_playlists.sh)

Can take file(s) with URIs as arguments or read from standard input for chaining with other tools

Useful for chaining with other tools (eg. spotify_playlist_tracks_uri.sh / spotify_search_uri.sh in this repo, or
tracks_already_in_playlists.sh in the HariSekhon/Spotify-Playlists github repo) or loading from saved spotify format
playlists (eg. TODO playlists dumped by spotify_backup*.sh / spotify_playlist_tracks_uri.sh)

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

delete_from_playlist(){
    if [ $# -lt 1 ]; then
        echo "Error: no IDs passed to delete_from_playlist()" >&2
        exit 1
    fi
    local uri_array=""
    for id in "$@"; do
        # requires explicit track URI type since could also be episodes added to playlist
        uri_array+="{\"uri\": \"spotify:track:$id\"}, "
    done
    uri_array="${uri_array%, }"
    timestamp "removing ${#@} tracks from playlist '$playlist_name'"
    "$srcdir/spotify_api.sh" "$url_path" -X DELETE -d '{"tracks": '"[$uri_array]}" >/dev/null  # ignore the { "spotify_snapshot": ... } json output
    ((count+=${#@}))
}

delete_URIs_from_file(){
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

        if [ "${#ids[@]}" -ge 100 ]; then
            delete_from_playlist "${ids[@]}"
            ids=()
        fi
    done < "$filename"

    delete_from_playlist "${ids[@]}"
}

for filename in "${@:-/dev/stdin}"; do
    delete_URIs_from_file "$filename"
done

timestamp "$count tracks deleted from playlist '$playlist_name'"
