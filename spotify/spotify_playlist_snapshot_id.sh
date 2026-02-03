#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#  args: harisekhon
#
#  Author: Hari Sekhon
#  Date: 2026-02-03 16:25:30 -0300 (Tue, 03 Feb 2026)
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

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck disable=SC1090,SC1091
. "$srcdir/lib/spotify.sh"

# shellcheck disable=SC1090,SC1091
. "$srcdir/lib/git.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Returns the Snapshot ID of a given Spotify playlist

Used by Spotify backup scripts like blacklisted_artists.sh in HariSekhon/Spotify-Playlists
to skip re-downloading an up to date playlist

If you pass 'liked' then retrieves the Last Added timestamp which is the equivalent for 'Liked Songs'

$usage_playlist_help

$usage_auth_help
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<playlist> [<playlist_id>]"

help_usage "$@"

min_args 1 "$@"

playlist="$1"
if [ "$playlist" = liked ] || [ "$playlist" = saved ]; then
    playlist="Liked Songs"
fi
liked(){
    [ "$playlist" = "Liked Songs" ]
}

playlist_id="${2:-}"

shift || :
shift || :

spotify_user

if liked; then
    export SPOTIFY_PRIVATE=1
fi

spotify_token

SECONDS=0

if liked; then
    "$srcdir/spotify_api.sh" "/v1/me/tracks?limit=1" |
    jq -r '.items[0].added_at'
else
    if is_blank "$playlist_id"; then
        playlist_id="$(SPOTIFY_PLAYLIST_EXACT_MATCH=1 "$srcdir/spotify_playlist_name_to_id.sh" "$playlist")"
    fi
    # optimization to pull only the fields we need without the first 100 tracks
    "$srcdir/spotify_api.sh" "/v1/playlists/$playlist_id?fields=snapshot_id" |
    jq -r '.snapshot_id'
fi
