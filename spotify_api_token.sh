#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-06-23 17:59:52 +0100 (Tue, 23 Jun 2020)
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

# shellcheck disable=SC2034
usage_description="
Returns a Spotify access token from the Spotify API

Requires \$SPOTIFY_CLIENT_ID and \$SPOTIFY_CLIENT_SECRET to be defined in the environment

Uses the Client Credenials authorization flow as documented here:

https://developer.spotify.com/documentation/general/guides/authorization-guide/#client-credentials-flow
"

[ -n "${DEBUG:-}" ] && set -x
srcdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck disable=SC1090
. "$srcdir/lib/utils.sh"

help_usage "$@"

check_env_defined "SPOTIFY_CLIENT_ID"
check_env_defined "SPOTIFY_CLIENT_SECRET"

output="$(curl -sSL -u "$SPOTIFY_CLIENT_ID:$SPOTIFY_CLIENT_SECRET" -X 'POST' -d 'grant_type=client_credentials' https://accounts.spotify.com/api/token)"
# shellcheck disable=SC2181
if [ $? != 0 ]; then
    echo "$output" >&2
    exit 1
fi

jq -r '.access_token' <<< "$output"
