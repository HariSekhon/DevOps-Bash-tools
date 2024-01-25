#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-07-24 19:05:25 +0100 (Fri, 24 Jul 2020)
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
Deletes Spotify URIs from a given playlist

Playlist must be specified as the first argument and can be either a Spotify playlist ID or a full playlist name (see spotify_playlists.sh)

Can take file(s) with URIs as arguments or read from standard input for chaining with other tools

Input formats can be IDs or any standard Spotify URI format, eg:

spotify:track:<ID>
https://open.spotify.com/track/<ID>
<ID>

or can be prefixed with track position in the playlist (zero-indexed) if you only want to delete a single instance of the song (useful when removing only duplicates), separated by either space:

<track_position>      spotify:track:<ID>
<track_position>      https://open.spotify.com/track/<ID>
<track_position>      <ID>

or a colon:

<track_position>:spotify:track:<ID>
<track_position>:https://open.spotify.com/track/<ID>
<track_position>:<ID>


Useful for chaining with other tools (eg. spotify_playlist_tracks_uri.sh / spotify_search_uri.sh in this repo, or
tracks_already_in_playlists.sh in the HariSekhon/Spotify-Playlists github repo) or loading from saved spotify format
playlists (eg. TODO playlists dumped by spotify_backup*.sh / spotify_playlist_tracks_uri.sh)

Caveat: won't check the tracks are already in the playlist, will simply fire batch delete API calls and count the number of tracks requested to be removed, so repeated runs of the same URIs fed in will give the same results, which might mislead you to thinking they weren't remove the first time around, when they've already been removed


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

snapshot_id=""

# Takes track IDs or track position:ID for more specific deletes
delete_from_playlist(){
    if [ $# -lt 1 ]; then
        echo "Error: no IDs passed to delete_from_playlist()" >&2
        exit 1
    fi
    local uri_array=""
    local track_position
    local id
    for id in "$@"; do
        if [[ "$id" =~ ^[[:digit:]]+: ]]; then
            # extract first column for track position
            track_position="${id%%:*}"
            # don't try to calculate this, the numbers aren't as predicted during testing, use snapshot consistency instead
            #((track_position-=count))
            # keep zero-indexed for compatability with other tools - no longer necessary, they return zero indexed now
            #((track_position-=1)) # convert one-indexed (eg. from grep) to zero-indexed for Spotify API
            id="${id#*:}"
            # requires explicit track URI type since could also be episodes added to playlist
            uri_array+="{\"uri\": \"spotify:track:$id\", \"positions\": [$track_position]}, "
            if [ -z "$snapshot_id" ]; then
                # get the Snapshot ID of the playlist before we start deleting for consistency and use this for all rounds of deletions
                snapshot_id="$("$srcdir/spotify_api.sh" "${url_path%/tracks}?fields=snapshot_id" | jq -r '.snapshot_id')"
            fi
        else
            # requires explicit track URI type since could also be episodes added to playlist
            uri_array+="{\"uri\": \"spotify:track:$id\"}, "
        fi
    done
    uri_array="${uri_array%, }"
    timestamp "removing ${#@} tracks from playlist '$playlist_name'"
    json_payload='{"tracks": '"[$uri_array]"
    #if [ -n "$snapshot_id" ] && [ "$snapshot_id" != null ]; then
    # let it send null and fail as we should never get back null
    if [ -n "$snapshot_id" ]; then
        json_payload+=", \"snapshot_id\": \"$snapshot_id\""
    fi
    json_payload+="}"
    local output
    output="$("$srcdir/spotify_api.sh" "$url_path" -X DELETE -d "$json_payload")"
    #die_if_error_field "$output"
    warn_if_error_field "$output"
    ((count+=${#@}))
    # don't take the new snapshot ID - use the one from before we start deleting for consistency otherwise the second round of deletes will fail
    #snapshot_id="$(jq -r '.snapshot_id' <<< "$output")"
    #if is_blank "$snapshot_id"; then
    #    die "Spotify API returned blank snapshot id, please investigate with DEBUG=1 mode"
    #fi
    #if [ "$snapshot_id" = null ]; then
    #    die "Spotify API returned snapshot_id '$snapshot_id', please investigate with DEBUG=1 mode"
    #fi
}

delete_URIs_from_playlist(){
    declare -a ids
    ids=()
    while read -r track_uri; do
        track_position=""
        if [[ "$track_uri" =~ ^[[:digit:]]+[:[:space:]]+ ]]; then
            # extract first column for track position
            track_position="${track_uri%%[:[:space:]]*}"

            # remove first column of track position
            track_uri="${track_uri#*[:[:space:]]}"

            # strip any remaining leading whitespace without subshelling to sed
            track_uri="${track_uri#"${track_uri%%[!:[:space:]]*}"}"
        fi
        if is_blank "$track_uri"; then
            continue
        fi
        if is_local_uri "$track_uri"; then
            continue
        fi
        if [ -n "${SPOTIFY_DELETE_IGNORE_IRREGULAR_IDS:-}" ]; then
            id="$(validate_spotify_uri "$track_uri" || :)"
            if ! is_spotify_playlist_id "$id"; then
                timestamp "skipping deleting irregular ID '$id'"
                continue
            fi
        else
            id="$(validate_spotify_uri "$track_uri")"
        fi

        if [ -n "$track_position" ]; then
            ids+=("$track_position:$id")
        else
            ids+=("$id")
        fi

        if [ "${#ids[@]}" -eq 100 ]; then
            delete_from_playlist "${ids[@]}"
            sleep 1
            ids=()
        fi
    done

    if [ "${#ids[@]}" -gt 0 ]; then
        delete_from_playlist "${ids[@]}"
    fi
}

for filename in "${@:-/dev/stdin}"; do
    delete_URIs_from_playlist < "$filename"
done

timestamp "$count tracks deleted from playlist '$playlist_name'"
