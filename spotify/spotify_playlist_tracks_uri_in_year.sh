#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#  args: "The 70s" 197.
#
#  Author: Hari Sekhon
#  Date: 2020-11-18 12:07:54 +0000 (Wed, 18 Nov 2020)
#
#  https://github.com/HariSekhon/Spotify-Playlists
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
Returns the URIs of all tracks in a playlist which originated in the given year regex

Useful to find tracks from a given year or decade from existing playlists to create more specialised playlists

The regex is an anchored BRE format regex. Typically you'll want to provide a simple 4-digit year or 3 digits and a dot for a decade


Example:

This returns everything in MyPlaylist that had an original release date in the 1980s:

    ${0##*/} MyPlaylist 198.

Even if the track in the playlist is from a compilation released later, it will find the original release date by doing
a targeted search for that track using the Spotify API


Caveat: not every single track is findable in the Spotify Search API - there are some rare edge cases where certain versions won't be found even with broader simpler searches (eg. Nadia Ali  Call My Name Spencer Hill Radio Edit).
        Such tracks are now skipped rather than raising errors as it's better to take the 99% success rate than deal with the rare data issues in the Spotify API
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<playlist> <year_regex> [<curl_options>]"

help_usage "$@"

min_args 2 "$@"

playlist="$1"
year_regex="$2"
shift || :
shift || :

if is_blank "$playlist"; then
    usage "playlist not defined"
fi

if is_blank "$year_regex"; then
    usage "year regex not defined"
fi

# allow filtering private playlists
export SPOTIFY_PRIVATE=1

spotify_token

playlist_id="$("$srcdir/spotify_playlist_name_to_id.sh" "$playlist" "$@")"

# defined in lib/spotify.sh
# shellcheck disable=SC2154
url_path="/v1/playlists/$playlist_id/tracks?limit=100&offset=$offset"

while not_null "$url_path"; do
    output="$("$srcdir/spotify_api.sh" "$url_path" "$@")"
    #die_if_error_field "$output"
    url_path="$(get_next "$output")"
    # XXX: very important - do not quote, this only works in very simple cases and doesn't work in artist:"quoted" track:"quoted" or even "artist:blah track:blah" formats
    # quotes are part of the data in track names, so this is highly breakable, using artist: track: is the more specific method anyway, just stick with that
    jq -r '.items[].track |
           [ .uri,
             "artist:" + ([.artists[].name] | join(" ")),
             "track:" + .name
           ] | @tsv' <<< "$output" |
    while read -r uri search_criteria; do
        #log "searching for year - $search_criteria"
        artist_search_terms="${search_criteria%%track:*}"
        artist="${artist_search_terms#artist:}"
        track="${search_criteria##*track:}"
        log "searching for year for:  $artist - $track"
        # Spotify API can handle single quotes (strips them out) but breaks if you URL encode them! So remove them rather than URL encode
        artist="${artist//\'/}"
        # to be able to query artists with unicode characters eg. Blue Öyster Cult
        artist="$("$srcdir/../bin/urlencode.sh" <<< "$artist")"
        # strip single quotes as raw single quotes qork but url encoding single quotes breaks the API
        track="${track//\'/}"
        track="$("$srcdir/../spotify-tools/normalize_tracknames.pl" <<< "$track" | "$srcdir/../bin/urlencode.sh")"
        # XXX: this track isn't found with but is if you leave off the artist: and track: prefixes then you find the other versions of it which are found in the API - this is a better trade off than finding nothing
        #
        #      artist:Nadia track:Call My Name
        #
        #      Sultan,Sultan + Shepard,Nadia Ali - Call My Name - Spencer & Hill Remix
        #
        log "searching for year - $artist - $track"
        #year="$("$srcdir/spotify_release_year.sh" "$artist" "$track")"
        # XXX: hack to ignore fringe cases where search doesn't find anything due to weird characters or encoding issues or edge cases like 'Nadia Ali      Call My Name (Spencer & Hill Radio Edit) (feat. Nadia Ali)' which doesn't appear in even basic searches such as 'Nadia Ali   Call My Name Radio Edit') even though other versions do
        year="$("$srcdir/spotify_release_year.sh" "$artist" "$track" || :)"
        if [ -z "$year" ]; then
            log "failed to find year for:  $artist - $track"
            if [ -n "${DEBUG:-}" ]; then
                echo >&2
            fi
            continue
        fi
        log "got year $year"
        if [[ "$year" =~ ^$year_regex$ ]]; then
            echo "$uri" |
            if [ -n "${DEBUG:-}" ]; then
                "$srcdir/spotify_uri_to_name.sh"
                echo >&2
            else
                cat
            fi
        fi
    done
done
