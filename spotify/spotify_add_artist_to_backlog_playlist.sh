#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2025-07-08 17:11:29 +0200 (Tue, 08 Jul 2025)
#
#  https///github.com/HariSekhon/DevOps-Bash-tools
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
. "$srcdir/lib/utils.sh"

playlist="Discover Backlog"

# shellcheck disable=SC2034,SC2154
usage_description="
Searches for the tracks of a given artist and adds them to the \"$playlist\" playlist

Because Spotify's UI is horrible to try to get all the tracks from the discographies and add them to a playlist manually

By defaults limits to 1000 tracks, which should cover all of the artist's work

If you need to change this limit, set:

    export SPOTIFY_SEARCH_LIMIT=5000

Expects the \"$playlist\" playlist to already exist

Uses adjacent scripts:

    spotify_search_uri.sh

    spotify_add_to_playlist.sh
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<artist>"

help_usage "$@"

num_args 1 "$@"

artist="$1"

export SPOTIFY_SEARCH_LIMIT="${SPOTIFY_SEARCH_LIMIT:-1000}"

"$srcdir/spotify_search_uri.sh" artist:"$artist" |
tee >("$srcdir/spotify_uri_to_name.sh") |
"$srcdir/spotify_add_to_playlist.sh" "$playlist"
