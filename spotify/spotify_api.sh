#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  args: /v1/users/harisekhon
#
#  Author: Hari Sekhon
#  Date: 2020-06-23 17:17:18 +0100 (Tue, 23 Jun 2020)
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
Queries the given Spotify API endpoint

API endpoints you can query with this code:

https://developer.spotify.com/documentation/web-api/reference/

For private user data endpoints you must export SPOTIFY_PRIVATE=1

$usage_auth_help


Examples:

spotify_api.sh /v1/users/harisekhon

SPOTIFY_PRIVATE=1 spotify_api.sh /v1/me/tracks

Used by adjacent spotify_*.sh scripts for more serious usage

"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="/url/path [<curl_options>]"

help_usage "$@"

min_args 1 "$@"

url_path="$1"

shift || :

if [[ "$url_path" =~ /v1/me/ ]]; then
    export SPOTIFY_PRIVATE=1
fi

spotify_token

url_base="https://api.spotify.com"
url_path="${url_path##$url_base}"
url_path="${url_path##/}"

export TOKEN="$SPOTIFY_ACCESS_TOKEN"

# the Spotify API is very unreliable and often gets 502 errors
# seen 20 x HTTP 500 errors from the API in a row :-/
MAX_RETRIES="30" retry 300 "$srcdir/../bin/curl_auth.sh" -sSL --fail "$url_base/$url_path" "$@"
