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
Queries the Spotify API

Requires \$SPOTIFY_ACCESS_TOKEN in the environment, or \$SPOTIFY_CLIENT_ID and \$SPOTIFY_CLIENT_SECRET, in which case it'll call spotify_access_token.sh to generate a new token for the duration of this script

You may want to do this in your shell environment for efficiency to avoid regenerating API tokens for every script call within the hour (just remember to remove it after the expiry, usually 1 hour)

export SPOTIFY_ACCESS_TOKEN=\"\$('$srcdir/spotify_api_token.sh')\"

Generate an App client ID and secret here:

https://developer.spotify.com/dashboard/applications

Uses the Client Credenials authorization flow as documented here:

https://developer.spotify.com/documentation/general/guides/authorization-guide/#client-credentials-flow
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

url_path="${url_path##/}"

curl -sSL -H "Authorization: Bearer $SPOTIFY_ACCESS_TOKEN" "https://api.spotify.com/$url_path" "$@"
