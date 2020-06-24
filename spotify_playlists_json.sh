#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-06-24 01:17:21 +0100 (Wed, 24 Jun 2020)
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
usage_args="[<curl_options>]"

# shellcheck disable=SC2034
usage_description="
Returns spotify playlists in raw JSON format for \$SPOTIFY_USER or current user to which the \$SPOTIFY_ACCESS_TOKEN belongs

Requires \$SPOTIFY_ACCESS_TOKEN in the environment (can generate from spotify_api_token.sh) or will auto generate from \$SPOTIFY_CLIENT_ID and \$SPOTIFY_CLIENT_SECRET if found in the environment

export SPOTIFY_ACCESS_TOKEN=\"\$('$srcdir/spotify_api_token.sh')\"

Caveat: limited to 50 public playlists due to Spotify API, must specify OFFSET=50 to get next 50. This script does not iterate each page automatically because the output would be nonsensical multiple json outputs so you must iterate yourself and process each json result in turn

For an example of how to use this to return and process multiple paged requests see spotify_playlists.sh
"

# shellcheck disable=SC1090
. "$srcdir/lib/utils.sh"

help_usage "$@"

if [ -n "${SPOTIFY_USER:-}" ]; then
    user="users/$SPOTIFY_USER"
else
    # must not have 'users/' prefix (will go to an actual literal user called 'me' in that case)
    user="me"
fi

offset="${OFFSET:-0}"

"$srcdir/spotify_api.sh" "/v1/$user/playlists?limit=50&offset=$offset" "$@"
