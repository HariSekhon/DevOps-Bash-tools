#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  args: "Foo Fighters" | tee /dev/stderr | spotify_uri_to_name.sh
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

# https://developer.spotify.com/documentation/web-api/reference/search

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck disable=SC1090,SC1091
. "$srcdir/lib/spotify.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Searches the Spotify API for and returns alternate track URIs for the given URIs (up to 10)

Accepts URIs as either args or from standard input

Uses spotify_search_json.sh which supports the following environment variable options:


$usage_auth_help
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<track_uri_or_files>]"

help_usage "$@"

#min_args 1 "$@"

export SPOTIFY_SEARCH_LIMIT=10

spotify_token

SPOTIFY_TSV=1 "$srcdir/spotify_uri_to_name.sh" "$@" |
while IFS=$'\t' read -r artist track; do
    artist="$(urlencode.sh <<< "$artist")"
    track="$(urlencode.sh <<< "$track")"
    "$srcdir/spotify_search_uri.sh" artist:"$artist" track:"$track"
done
