#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-11-30 17:29:53 +0000 (Mon, 30 Nov 2020)
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
Deletes tracks from the given playlist if their URIs are found in the subsequently given playlists

This is useful to delete things from TODO playlists that are already in a bunch of other playlists

The first playlist is the one to delete the tracks in, this will be your TODO playlist

Subsequent playlist args are the source playlists to check for already existing tracks
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
        command ggrep "$@"
    }
fi

for playlist in "$@"; do
    "$srcdir/spotify_playlist_tracks_uri.sh" "$playlist"
done |
grep -Fxf <("$srcdir/spotify_playlist_tracks_uri.sh" "$playlist_to_delete_from") |
"$srcdir/spotify_delete_from_playlist.sh" "$playlist_to_delete_from"
