#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-06-24 01:17:21 +0100 (Wed, 24 Jun 2020)
#
#  https://github.com/HariSekhon/DevOps-Bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/HariSekhon
#

# https://developer.spotify.com/documentation/web-api/reference/playlists/get-list-users-playlists/

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck disable=SC1090,SC2154
. "$srcdir/lib/spotify.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Returns the list of Spotify public playlists in raw JSON format for the given Spotify user

\$SPOTIFY_USER can be used from the evironment if no first argument is given

Caveat: limited to 50 public playlists due to Spotify API, must specify OFFSET=50 to get next 50.
        This script does not iterate each page automatically because the output would be nonsensical
        multiple json outputs so you must iterate yourself and process each json result in turn
        For an example of how to do this and process multiple paged requests see spotify_playlists.sh

$usage_playlist_help

$usage_auth_help
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<spotify_username> [<curl_options>]"

help_usage "$@"

if not_blank "${SPOTIFY_PRIVATE:-}"; then
    # $limit/$offset defined in lib/spotify.sh
    # shellcheck disable=SC2154
    url_path="/v1/me/playlists?limit=$limit&offset=$offset"
else
    user="${1:-${SPOTIFY_USER:-}}"
    if is_blank "$user"; then
        # /v1/me/playlists gets an authorization error and '/v1/users/me/playlists' returns the wrong user, an actual literal user called 'me'
        #user="me"
        usage "user not specified"
    fi
    # $limit/$offset defined in lib/spotify.sh
    # shellcheck disable=SC2154
    url_path="/v1/users/$user/playlists?limit=$limit&offset=$offset"
fi

shift || :

"$srcdir/spotify_api.sh" "$url_path" "$@"
