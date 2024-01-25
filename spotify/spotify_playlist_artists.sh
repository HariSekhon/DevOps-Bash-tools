#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  args: "Upbeat & Sexual Pop"
#  args: 64OO67Be8wOXn6STqHxexr
#
#  Author: Hari Sekhon
#  Date: 2020-10-31 10:07:23 +0000 (Sat, 31 Oct 2020)
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

# shellcheck disable=SC1090,SC2154
. "$srcdir/lib/spotify.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Returns only the artist names for the tracks in a given Spotify playlist

Playlist argument can be a playlist name or a playlist ID (get this from spotify_playlists.sh)

\$SPOTIFY_PLAYLIST can be used from environment if no first argument is given


Outputs 1 artist per line, so tracks with multiple artists become multiple artist lines

This is useful for piping to 'sort | uniq -c' to:

1. Find top artists per playlist by counting the number of tracks per artist
2. Find top blacklisted artists by doing the above for my Blacklist playlist (done the Spotify-Playlists repo)

Example:

    SPOTIFY_PRIVATE=1 spotify_playlist_artists.sh Blacklist | sort | uniq -c | sort -k1nr

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
    jq -r '.items[].track | select(.artists) | .artists[].name' <<< "$output" |
    sed '
        s/^[[:space:]]*//;
        s/[[:space:]]*$//;
        /^[[:space:]]*$/d;
    '
}

while not_null "$url_path"; do
    output="$("$srcdir/spotify_api.sh" "$url_path" "$@")"
    #die_if_error_field "$output"
    url_path="$(get_next "$output")"
    output
done
