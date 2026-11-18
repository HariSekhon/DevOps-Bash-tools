#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  args: "Best of 1964"
#
#  Author: Hari Sekhon
#  Date: 2026-11-19 00:42:36 +0800 (Thu, 19 Nov 2026)
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

# shellcheck disable=SC1090,SC1091,SC2154
. "$srcdir/lib/spotify.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Adds given Spotify playlist(s) to publicly displayed profile

Playlist arguments can be any mix of playlist names or playlist ID (get this from spotify_playlists.sh)

Written to automate adding all my 'Best of NNNN' year 50+ playlists

$usage_playlist_help

$usage_auth_help
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<playlist> [<playlist2> <playlist3> ...]"

help_usage "$@"

min_args 1 "$@"

# without this only finds public playlists that have also already been added to profile
# so we always need to use a private token
export SPOTIFY_PRIVATE=1

spotify_token

for playlist_id; do
    timestamp "Resolving Playlist Name <=> ID: $playlist_id"
    playlist_id="$("$srcdir/spotify_playlist_name_to_id.sh" "$playlist_id")"
    playlist_name="$("$srcdir/spotify_playlist_id_to_name.sh" "$playlist_id")"
    timestamp "Playlist Name: $playlist_name"
    timestamp "Playlist Name: $playlist_id"

    timestamp "Adding playlist to public profile: $playlist_name"
    "$srcdir/spotify_api.sh" \
        "https://api.spotify.com/v1/playlists/$playlist_id" \
        -X PUT \
        -d '{"public":true}'
    timestamp "Playlist added to public profile"
    echo
done
