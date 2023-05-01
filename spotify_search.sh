#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  args: "Foo Fighers"
#
#  Author: Hari Sekhon
#  Date: 2020-07-05 14:33:55 +0100 (Sun, 05 Jul 2020)
#
#  https://github.com/HariSekhon/DevOps-Bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/HariSekhon
#

# https://developer.spotify.com/documentation/web-api/reference/search/search/

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck disable=SC1090,SC1091
. "$srcdir/lib/spotify.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Searches the Spotify API and returns the first N tracks / artists / albums that match the given search expression

See this page for documentation on how to write query expressions:

https://developer.spotify.com/documentation/web-api/reference/search/search/

Examples:

Find tracks called 'arlandria' by artist 'foo fighters':

    ${0##*/} artist:foo fighters track:arlandria


Find top 5 matching artists with 'foo' in the name:

    SPOTIFY_SEARCH_TYPE=artist SPOTIFY_SEARCH_LIMIT=5 ${0##*/} foo


Environment variable options:

\$SPOTIFY_SEARCH_TYPE  = track # default
                        artist
                        album

\$SPOTIFY_SEARCH_LIMIT = 1 # default

\$SPOTIFY_SEARCH_OFFSET = 0 # default


Uses spotify_search_json.sh - see there for more searching defails.


$usage_auth_help
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="'<search_expression>"

help_usage "$@"

min_args 1 "$@"

"$srcdir/spotify_search_json.sh" "$@" |

if [ "${SPOTIFY_SEARCH_TYPE:-}" = "artist" ]; then
    jq -r '.artists.items[].name'
elif [ "${SPOTIFY_SEARCH_TYPE:-}" = "album" ]; then
    jq -r '.albums.items[] | [([.artists[].name] | join(",")), "-", .name ] | @tsv' |
    tr '\t' ' '
else
    jq -r '.tracks.items[] | [([.artists[].name] | join(",")), "-", .name ] | @tsv' |
    tr '\t' ' '
fi
