#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-11-30 17:29:53 +0000 (Mon, 30 Nov 2020)
#
#  https://github.com/HariSekhon/bash-tools
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

# shellcheck disable=SC1090
. "$srcdir/lib/utils.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Deletes tracks from the given playlist if their URIs are found in the subsequently given playlists

This is useful to delete things from TODO playlists that are already in a bunch of other playlists
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<playlist_name_or_id> <playlist_name_or_id> [<playlist_name_or_id>]"

help_usage "$@"

min_args 2 "$@"

playlist_to_delete_from="$1"
shift || :

for playlist in "$@"; do
    "$srcdir/spotify_playlist_tracks_uri.sh" "$playlist"
done |
"$srcdir/spotify_delete_from_playlist.sh" "$playlist_to_delete_from"
