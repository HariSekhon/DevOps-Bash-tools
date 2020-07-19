#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-06-23 17:17:18 +0100 (Tue, 23 Jun 2020)
#
#  https://github.com/harisekhon/bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/harisekhon
#

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="/url/path [<curl_options>]"

# shellcheck disable=SC2034
usage_description="
Queries the given Spotify API endpoint

Requires \$SPOTIFY_ACCESS_TOKEN in the environment, or \$SPOTIFY_ID and \$SPOTIFY_SECRET, in which case it'll call spotify_access_token.sh to generate a new token for the duration of this script

If accessing API endpoints for private user data that require authorized tokens, such as /v1/me/... , then you'll need to export SPOTIFY_PRIVATE=1 before generating a token with interactive authorization pop-up due to quirks in the Spotify API

For efficiency to avoid regenerating API tokens for every script call, do the following once an hour in your shell:

export SPOTIFY_ACCESS_TOKEN=\"\$('$srcdir/spotify_api_token.sh')\"

Generate an App client ID and secret here and add a callback URL of 'http://localhost:12345/callback':

https://developer.spotify.com/dashboard/applications

API documentation for calls to make:

https://developer.spotify.com/documentation/web-api/reference/

Eg.

spotify_api.sh /v1/users/harisekhon

SPOTIFY_PRIVATE=1 spotify_api.sh /v1/me/tracks

Used by adjacent spotify_*.sh scripts for more serious usage
"

# shellcheck disable=SC1090
. "$srcdir/lib/utils.sh"

help_usage "$@"

min_args 1 "$@"

url_path="$1"

shift || :

if [ -z "${SPOTIFY_ACCESS_TOKEN:-}" ]; then
    SPOTIFY_ACCESS_TOKEN="$("$srcdir/spotify_api_token.sh")"
fi

url_base="https://api.spotify.com"
url_path="${url_path##$url_base}"
url_path="${url_path##/}"

curl -sSL -H "Authorization: Bearer $SPOTIFY_ACCESS_TOKEN" "$url_base/$url_path" "$@"
