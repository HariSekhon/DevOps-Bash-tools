#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  args: "Upbeat & Sexual Pop"
#  args: 64OO67Be8wOXn6STqHxexr
#
#  Author: Hari Sekhon
#  Date: 2026-01-29 18:40:46 -0400 (Thu, 29 Jan 2026)
#
#  https://github.com/HariSekhon/DevOps-Bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn
#  and optionally send me feedback to help steer this or other code I publish
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
Returns track URIs from the given Spotify playlist for a specific year or range of years

Useful for filtering tracks to add to my best of each decade playlists

Playlist argument can be a playlist name or ID (see spotify_playlists.sh)

The year can be one of:

- an integer
- a year range in the format '<start>-<end>' eg. '2000-2009'
- an entire decade such as '1980s', '1990s', '2000s', '2010s', '2020s'
- a decade range such as '1990s-2000s'

\$SPOTIFY_PLAYLIST can be used from environment if no first argument is given

$usage_playlist_help

$usage_auth_help
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<playlist> <year_or_range> [<curl_options>]"

help_usage "$@"

playlist_id="${1:-${SPOTIFY_PLAYLIST:-}}"
year_arg="${2:-}"
shift || :
shift || :

if is_blank "$playlist_id"; then
    usage "playlist not defined"
fi

if is_blank "$year_arg"; then
    usage "year or range not defined"
fi

decade_to_range() {
    local decade="$1"
    local start="${decade%s}"   # remove trailing 's'
    echo "$start $((start + 9))"
}

if [[ "$year_arg" =~ ^([0-9]{4})$ ]]; then
    # Single year
    year_start="$year_arg"
    year_end="$year_arg"
elif [[ "$year_arg" =~ ^([0-9]{4})-([0-9]{4})$ ]]; then
    # Year range
    year_start="${BASH_REMATCH[1]}"
    year_end="${BASH_REMATCH[2]}"
elif [[ "$year_arg" =~ ^([0-9]{4})s$ ]]; then
    # Single decade
    read -r year_start year_end < <(decade_to_range "$year_arg")
elif [[ "$year_arg" =~ ^([0-9]{4}s)-([0-9]{4}s)$ ]]; then
    # Decade range
    read -r year_start _ < <(decade_to_range "${BASH_REMATCH[1]}")
    read -r _ year_end < <(decade_to_range "${BASH_REMATCH[2]}")
else
    usage "invalid year or range: '$year_arg'"
fi

spotify_token

playlist_id="$("$srcdir/spotify_playlist_name_to_id.sh" "$playlist_id" "$@")"

# $offset defined in lib/spotify.sh
# shellcheck disable=SC2154
url_path="/v1/playlists/$playlist_id/tracks?limit=100&offset=$offset"

print_output(){
    #jq -r '.items[] | select(.track.uri) | .track.uri' <<< "$output"
    # filter tracks by release year, works for singles, EPs, albums
    jq -r --arg start "$year_start" --arg end "$year_end" '
        .items[]
        | select(.track.uri)
        | select(.track.album.release_date | test("^[0-9]{4}"))
        | .track as $t
        | ($t.album.release_date[0:4] | tonumber) as $year
        | select($year >= ($start | tonumber) and $year <= ($end | tonumber))
        | $t.uri
    ' <<< "$output"
}

while not_null "$url_path"; do
    output="$("$srcdir/spotify_api.sh" "$url_path" "$@")"
    #die_if_error_field "$output"
    url_path="$(get_next "$output")"
    print_output
    # slow down a bit to try to reduce hitting Spotify API rate limits and getting 429 errors on large playlists
    #sleep 0.1
done
