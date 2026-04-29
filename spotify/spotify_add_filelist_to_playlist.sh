#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2026-04-30 00:07:27 +0200 (Thu, 30 Apr 2026)
#
#  https///github.com/HariSekhon/DevOps-Bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn
#  and optionally send me feedback
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
Searches the Spotify API for each track in a given file and adds the first matching track to the given playlist

File format:

Artist   \\t Song
Artist 2 \\t Song 2

Playlist can be given as a name or a playlist ID (the latter saves a name lookup and is more precise)
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<artist-tracks.txt> <playlist>"

help_usage "$@"

num_args 2 "$@"

filelist="$1"
playlist="$2"

if ! [ -f "$filelist" ]; then
    usage "No file given"
elif ! [ -s "$filelist" ]; then
    usage 'Given file is empty!'
elif is_blank "$("$srcdir/../bin/decomment.sh" "$filelist")"; then
    usage 'Given file is empty except for comments / whitespace!'
fi

spotify_token

timestamp "Resolving playlist to ID one time up front for efficiency: $playlist"
playlist_id="$("$srcdir/spotify_playlist_name_to_id.sh" "$playlist")"
timestamp "Playlist ID determined to be: $playlist_id"

timestamp "Getting Existing Tracks from playlist (to avoid adding duplicates)"
existing_uris="$(
    "$srcdir/spotify_playlist_tracks_uri.sh" "$playlist_id"
)"

exitcode=0

# process file descriptor use here avoids subshells from losing the exitcode
"$srcdir/spotify_add_to_playlist.sh" "$playlist_id" < <(
    while IFS=$'\t' read -r artist track; do
        timestamp "Searching Spotify API - artist: $artist track: $track"
        artist_encoded="$("$srcdir/../bin/urlencode.sh" "$artist")"
        track_encoded="$("$srcdir/../bin/urlencode.sh" "$track")"
        track_uri="$(
            SPOTIFY_SEARCH_LIMIT=1 \
            "$srcdir/spotify_search_uri.sh" "$artist_encoded" "$track_encoded"
        )"
        if is_blank "$track_uri"; then
            timestamp "=> WARNING: no track found for: 'artist: $artist track: $track'"
            exitcode=1
            continue
        fi
        if grep -Fxq "$track_uri" <<< "$existing_uris"; then
            timestamp "=> Skipping adding existing track to playlist: $artist $track"
            continue
        fi
        timestamp "=> Adding track to playlist: $artist $track => $track_uri"
        echo "$track_uri"
    done < <(
        timestamp "Reading artist-track file: $filelist"
        "$srcdir/../bin/decomment.sh" "$filelist"
    )
)

timestamp "Done"
exit "$exitcode"
