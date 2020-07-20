#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  args: 64OO67Be8wOXn6STqHxexr
#
#  Author: Hari Sekhon
#  Date: 2020-07-05 14:33:55 +0100 (Sun, 05 Jul 2020)
#
#  https://github.com/harisekhon/bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/harisekhon
#

# https://developer.spotify.com/documentation/web-api/reference/search/search/

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck disable=SC1090
. "$srcdir/lib/spotify.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Searches the Spotify API and returns the first N tracks / artists / albums that match the given search expression

See this page for documentation on how to write query expressions:

https://developer.spotify.com/documentation/web-api/reference/search/search/

Example:

./${0##*/} artist:foo fighters track:arlandria


API JSON is returned, used by adjacent spotify_search*.sh scripts


Environment variable options:

\$SPOTIFY_SEARCH_TYPE  = track # default
                         artist
                         album

\$SPOTIFY_SEARCH_LIMIT = 1 # default

\$SPOTIFY_SEARCH_OFFSET = 0 # default


$usage_auth_msg
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="'<search_expression>"

help_usage "$@"

min_args 1 "$@"

# let user use full query and put artist: / album: / track: prefixes themselves
#if [ $# -gt 1 ]; then
#    artist="$1"
#    # encode spaces between search terms with %20 or +
#    artist="${artist// /+}"
#    shift || :
#fi
#track="$*"
#track="${track// /+}"

# this substitution doesn't work on $* so have to do it in 2 steps
search_terms="$*"
search_terms="${search_terms// /+}"

spotify_token

search_type="${SPOTIFY_SEARCH_TYPE:-track}"
if [ -n "${SPOTIFY_SEARCH_LIMIT:-}" ]; then
    limit="$SPOTIFY_SEARCH_LIMIT"
    if ! [[ "$limit" =~ ^[[:digit:]]+$ ]]; then
        echo "Invalid \$SPOTIFY_SEARCH_LIMIT = $limit found in environment" >&2
        exit 1
    fi
elif [ -n "${DEBUG:-}" ]; then
    limit=20
else
    limit=1
fi

offset="${SPOTIFY_SEARCH_OFFSET-0}"

url_path="/v1/search?type=$search_type&offset=$offset&limit=$limit"

# "Access token has no market information" - can't see how to set this in docs
#if [ -z "${NO_MARKET:-}" ]; then
#    # restrict to tracks available to the local market - this is more useful for being able to immediately use the returned URI to put in a playlist
#    url_path+="&market=from_token"
#fi

# quoting will preserve order of terms but will probably not work when putting artist and track name in the args
#url_path+="&q=\"$search_terms\""
url_path+="&q=$search_terms"
#url_path+="&q=artist:$artist+track:$track"

"$srcdir/spotify_api.sh" "$url_path"
