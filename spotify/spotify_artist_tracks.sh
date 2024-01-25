#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  args: "Sia"
#
#  Author: Hari Sekhon
#  Date: 2021-11-16 19:09:57 +0000 (Tue, 16 Nov 2021)
#
#  https://github.com/HariSekhon/DevOps-Bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/HariSekhon
#

# https://developer.spotify.com/documentation/web-api/reference/#/operations/get-an-artists-albums
#
# https://developer.spotify.com/documentation/web-api/reference/#/operations/get-an-albums-tracks

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck disable=SC1090,SC2154
. "$srcdir/lib/spotify.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Outputs track URIs for a given Spotify artist

Artist argument can be an artist name or preferably an artist ID (get this from the app -> Share -> Copy link to artist)

Useful to chain with the following scripts:

    spotify_add_to_playlist.sh
    spotify_delete_any_duplicates_in_playlist.sh


$usage_auth_help
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<spotify_artist>"

help_usage "$@"

min_args 1 "$@"

artist="$1"

shift || :

if is_blank "$artist"; then
    usage "artist not defined"
fi

spotify_token

if [ "${#artist}" = 22 ]; then
    artist_id="$artist"
else
    timestamp "resolving artist '$artist' to artist ID"
    artist_id="$(SPOTIFY_SEARCH_TYPE=artist SPOTIFY_SEARCH_LIMIT=50 "$srcdir/spotify_search_json.sh" "$artist" | jq -r ".artists.items[] | select(.name | ascii_downcase == \"$artist\") | .id" | head -n1)"
    timestamp "got artist ID '$artist_id'"
echo >&2
fi

# $offset defined in lib/spotify.sh
# shellcheck disable=SC2154
url_path="/v1/artists/$artist_id/albums?limit=50&offset=$offset&include_groups=album,single"  # API limit max is 50

timestamp "getting list of albums for artist"
albums="$(
    while not_null "$url_path"; do
        output="$("$srcdir/spotify_api.sh" "$url_path" "$@")"
        #die_if_error_field "$output"
        url_path="$(get_next "$output")"
        jq -r '.items[] | [.id, .name] | @tsv' <<< "$output"
    done
)"
echo >&2

offset=0
while read -r album_id album_name; do
    timestamp "getting list of tracks for album '$album_name'"
    # $offset defined in lib/spotify.sh
    # shellcheck disable=SC2154
    url_path="/v1/albums/$album_id/tracks?limit=50&offset=$offset"  # API limit max is 50

    while not_null "$url_path"; do
        output="$("$srcdir/spotify_api.sh" "$url_path" "$@")"
        #die_if_error_field "$output"
        url_path="$(get_next "$output")"
        #jq -r '.items[] | [.id, .name] | @tsv' <<< "$output"
        jq -r '.items[].id' <<< "$output"
    done
done <<< "$albums"
