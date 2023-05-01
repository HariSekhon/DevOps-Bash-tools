#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#  args: Dance∕Pop∕House∕Trance∕DnB∕Electronica∕Gym spotify:track:5Vy3sdJZJ6AnDChSfNtKs8
#
#  Author: Hari Sekhon
#  Date: 2020-11-19 21:23:19 +0000 (Thu, 19 Nov 2020)
#
#  https://github.com/HariSekhon/DevOps-Bash-tools
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
Prints the offset of a given spotify track URI in a given playlist

Useful to find the offset to use to continue processing a large partially processed playlist because Spotify API tokens are only valid for 1 hour and some playlists with several thousand tracks take longer than that to process eg. spotify_playlist_tracks_uri_in_year.sh)

Playlist can be given as a name or id

URI must be in the form of spotify:track:uri as this is the native format in the playlist we are looking for


$usage_playlist_help

$usage_auth_help
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<playlist> <spotify:track:uri> [<curl_options>]"

help_usage "$@"

min_args 2 "$@"

playlist="$1"
uri="$2"
shift || :
shift || :

if is_blank "$playlist"; then
    usage "playlist not defined"
fi

if is_blank "$uri"; then
    usage "URI not defined"
fi

# discard the id returned
validate_spotify_uri "$uri" >/dev/null

if ! [[ "$uri" =~ ^spotify:track:[[:alnum:]]+$ ]]; then
    usage "URI must be in spotify:track:xxxxx... format"
fi

playlist_id="$("$srcdir/spotify_playlist_name_to_id.sh" "$playlist" "$@")"

# defined in lib/spotify.sh
# shellcheck disable=SC2154
url_path="/v1/playlists/$playlist_id/tracks?limit=100&offset=$offset"

output(){
    jq -r '.items[] | select(.track.uri) | .track.uri' <<< "$output"
}

while not_null "$url_path"; do
    output="$("$srcdir/spotify_api.sh" "$url_path" "$@")"
    #die_if_error_field "$output"
    jq -r '.items[].track.uri' <<< "$output" |
    while read -r this_uri; do
        if [ "$this_uri" = "$uri" ]; then
            echo "$offset"
            exit 0
        fi
        ((offset += 1))
    done
    url_path="$(get_next "$output")"
done
exit 1
