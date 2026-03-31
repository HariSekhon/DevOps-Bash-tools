#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  args: "Sia"
#
#  Author: Hari Sekhon
#  Date: 2026-03-31 00:29:48 -0500 (Tue, 31 Mar 2026)
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

# https://developer.spotify.com/documentation/web-api/reference/#/operations/get-an-artists-albums
#
set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck disable=SC1090,SC1091,SC2154
. "$srcdir/lib/spotify.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Returns the core discography of Albums and Singles for a given Spotify artist in chronological order

Output:

<release_date>    <type>    <ID>    <name>


Artist argument can be an artist name, ID, or link to artist (get this from the app -> Share -> Copy link to artist)

You can export SPOTIFY_MARKET=US or GB or similar to find releases not present in your local market

Used by adjacent script spotify_artist_tracks.sh

$usage_auth_help
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<spotify_artist_name_or_id>"

help_usage "$@"

min_args 1 "$@"

artist="$*"

market=""
if ! is_blank "${SPOTIFY_MARKET:-}"; then
    market="&market=$SPOTIFY_MARKET"
fi

# no longer passing $@ to spotify_api.sh as I never use this in practice
#shift || :

if is_blank "$artist"; then
    usage "Artist not defined"
fi

spotify_token

if [[ "$artist" =~ https://open.spotify.com/artist/ ]]; then
    artist="${artist#https://open.spotify.com/artist/}"
    artist="${artist%%\?*}"
fi

if [ "${#artist}" = 22 ] &&
   [[ "$artist" =~ ^[[:alnum:]]+$ ]]; then
    artist_id="$artist"
    timestamp "Resolving given artist ID"
    artist="$("$srcdir/spotify_api.sh" "/v1/artists/$artist_id" | jq -r '.name')"
    if is_blank "$artist"; then
        die "ERROR: failed to resolve artist name for given artist ID: $artist_id"
    fi
    timestamp "Artist ID '$artist_id' resolved to: $artist"
else
    timestamp "Resolving artist '$artist' to artist ID"
    artist_id="$(
        SPOTIFY_SEARCH_TYPE=artist \
        SPOTIFY_SEARCH_LIMIT=50 \
        "$srcdir/spotify_search_json.sh" "$artist" |
        jq -r "
            .artists.items[] |
            select(.name | ascii_downcase == \"$artist\") |
            .id
        " |
        head -n1
    )"
    is_blank "$artist_id" && die "ERROR: failed to get artist ID, is this name correct: $artist"
    timestamp "Got artist ID: $artist_id"
    echo >&2
fi

# $offset defined in lib/spotify.sh
# shellcheck disable=SC2154
# API limit max is 50 - we paginate further down
url_path="/v1/artists/$artist_id/albums?limit=50&offset=$offset&include_groups=album,single${market:+$market}"

timestamp "Getting discography of albums and singles for artist: $artist"
echo >&2
while not_null "$url_path"; do
    output="$("$srcdir/spotify_api.sh" "$url_path")"
    #die_if_error_field "$output"
    url_path="$(get_next "$output")"
    # for some reason the type field is always 'album' even for singles,
    # but using the album_type correctly differentiates albums vs singles
    jq -r '
        .items[] |
        [
            .release_date,
            .album_type,
            .id,
            .name
        ] |
        @tsv
    ' <<< "$output"
done |
sort
