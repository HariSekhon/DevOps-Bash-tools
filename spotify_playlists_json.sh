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

# https://developer.spotify.com/documentation/web-api/reference/playlists/get-list-users-playlists/

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<spotify_username> [<curl_options>]"

# shellcheck disable=SC2034
usage_description="
Returns the list of Spotify public playlists in raw JSON format for the given Spotify user

\$SPOTIFY_USER can be used from the evironment if no first argument is given

Requires \$SPOTIFY_CLIENT_ID and \$SPOTIFY_CLIENT_SECRET to be defined in the environment

Caveat: limited to 50 public playlists due to Spotify API, must specify OFFSET=50 to get next 50.
        This script does not iterate each page automatically because the output would be nonsensical
        multiple json outputs so you must iterate yourself and process each json result in turn
        For an example of how to do this and process multiple paged requests see spotify_playlists.sh

Caveat: due to limitations of the Spotify API, this only works for public playlists
"

# shellcheck disable=SC1090
. "$srcdir/lib/utils.sh"

help_usage "$@"

if [ -n "${1:-}" ]; then
    user="$1"
elif [ -n "${SPOTIFY_USER:-}" ]; then
    user="$SPOTIFY_USER"
else
    # /v1/me/playlists gets an authorization error and '/v1/users/me/playlists' returns the wrong user, an actual literal user called 'me'
    #user="me"
    usage "user not specified"
fi

shift || :

offset="${OFFSET:-0}"

"$srcdir/spotify_api.sh" "/v1/users/$user/playlists?limit=50&offset=$offset" "$@"
