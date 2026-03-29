#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  args: "https://open.spotify.com/local/Fabolous/R%26B%20Slowjamz%2C%20Disc%201/Into%20You/272"
#
#  Author: Hari Sekhon
#  Date: 2020-07-05 14:33:55 +0100 (Sun, 05 Jul 2020)
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

# shellcheck disable=SC2034,SC2154
usage_description="
Searches the Spotify API for the given local track URIs and returns the first Spotify URI match for each track

Useful to quickly replace local tracks with Spotify official tracks by copying the output URIs into playlists

eg.

    ${0##*} https://open.spotify.com/local/Donell%20Jones/R%26B%20Slowjamz%2C%20Disc%201/Where%20I%20Wanna%20Be/251

Returns

    spotify:track:1Jm1I3APcmVz3MqPr5vfTx

Which you can straight copy into your playlist


Uses the adjacent spotify_search_uri.sh script

$usage_auth_help
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="'[<local_track_uri> <local_track_uri2> ...]"

help_usage "$@"

#min_args 1 "$@"

spotify_token

if [ $# -eq 0 ]; then
    warn "Reading local track URIs from standard input"
    cat
else
    for track in "$@"; do
        echo "$track"
    done
fi |
while read -r line; do
    is_blank "$line" && continue
    if [[ "$line" =~ https://open.spotify.com/local/.*/.*/.* ]]; then
        echo "$line"
    else
        warn "Not a local track, skipping: $line"
    fi
done |
sed $'
    s|https://open.spotify.com/local/||;
    s|/[[:digit:]]*$||
    s|/.*/|\t|;
' |
# do not url decode, see spotify_search.sh --help for why this breaks the Spotify API
#"$srcdir/../bin/urldecode.sh |
while read -r artist track; do
    if is_blank "$artist" ||
       is_blank "$track"; then
        warn "Failed to parse track, skipping: $artist $track"
        continue
    fi
    "$srcdir/spotify_search_uri.sh" "artist:$artist" "track:$track"
done
