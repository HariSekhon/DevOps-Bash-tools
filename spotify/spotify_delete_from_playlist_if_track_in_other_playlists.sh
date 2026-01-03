#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2022-07-22 17:00:36 +0100 (Fri, 22 Jul 2022)
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
Deletes tracks from the given playlist if their 'Artist - Track' name matches exactly tracks found in the subsequently given playlists

This is useful to delete things from TODO playlists that are already in a bunch of other playlists

The first playlist is the one to delete the tracks in, this will be your TODO playlist

Subsequent playlist args are the source playlists to check for already existing tracks

Caveat: this is not as accurate as the default adjacent script spotify_delete_from_playlist_if_in_other_playlists.sh which only deletes on exact URI matches
        because you can have different versions of the same song with same 'Artist - Track' name
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<playlist_name_or_id> <playlist_name_or_id> [<playlist_name_or_id>]"

help_usage "$@"

min_args 2 "$@"

playlist_to_delete_from="$1"
shift || :

export SPOTIFY_PRIVATE=1

spotify_token

# BSD grep has a bug in grep -f, rely on GNU grep instead
if is_mac; then
    grep(){
        # handles grep -f properly
        command ggrep "$@"
    }
    sed(){
        # handles + matching properly
        command gsed "$@"
    }
fi

# switched to optimized awk filtering instead to avoid all regex character issues and also enforce ending anchoring
#grep -Ff <(
"$srcdir/../bin/text_filter_ending_substrings.sh" \
<(
    for playlist in "$@"; do
        timestamp "Getting list of Artist - Track names from source playlist: $playlist"
        "$srcdir/spotify_playlist_tracks.sh" "$playlist"
    done |
    sort -u #|
    # No longer needed since switching to optimized awk filtering using text_filter_ending_substrings.sh
    # XXX: anchor the track name as as suffix regex to prevent it accidentally removing '... (Remix)' or similar alternate versions of tracks
    #      this is a trade off vs using -F for regex safety - I am betting the fringe conditional of a track name having some character that
    #      breaks when used as a regex, possibly resulting in missing an odd track, is far less common than the other failure scenario of
    #      matching substings of track names. If this becomes a problem we can add escaping to special characters interpreted by regex
    #sed 's/$/$/'
) \
<(
    # Returns a list one per line in the format:
    #
    #   URI \t Artist - Track
    #
    timestamp "Getting list of URI + Artist - Track names from target playlist: $playlist_to_delete_from"
    "$srcdir/spotify_playlist_tracks_uri_artist_track.sh" "$playlist_to_delete_from"
) |
# get just the URIs of matching tracks
sed $'s/\t.*$//' |
"$srcdir/spotify_delete_from_playlist.sh" "$playlist_to_delete_from"
