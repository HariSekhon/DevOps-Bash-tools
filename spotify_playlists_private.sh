#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-06-24 09:30:53 +0100 (Wed, 24 Jun 2020)
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
usage_args="<spotify_user> [<curl_options>]"

# shellcheck disable=SC2034
usage_description="
Returns the list of Spotify private playlists for the given Spotify user

Returns only playlists that originate from the given Spotify user

\$SPOTIFY_USER can be used from the evironment if no first argument is given

Output Format:

<playlist_id>   <playlist_name>

Requires \$SPOTIFY_ID and \$SPOTIFY_SECRET to be defined in the environment

Caveat: due to limitations of the Spotify API, this requires an interactive web authorization or
\$SPOTIFY_ACCESS_TOKEN in the environment (can be obtained for an hour from spotify_api_token_interactive.sh)

If you have exported a non-authorized \$SPOTIFY_ACCESS_TOKEN in your environment (eg. from spotify_api_token.sh),
then this script will return no public playlists
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

url_path="/v1/users/$user/playlists?limit=50&offset=$offset"

output(){
    jq -r ".items[] | select(.owner.id == \"$user\") | select(.public != true) | [.id, .name] | @tsv" <<< "$output"
}

get_next(){
    jq -r '.next' <<< "$output"
}

if [ -z "${SPOTIFY_ACCESS_TOKEN:-}" ]; then
    SPOTIFY_ACCESS_TOKEN="$("$srcdir/spotify_api_token.sh")"
    export SPOTIFY_ACCESS_TOKEN
fi

while [ -n "$url_path" ] && [ "$url_path" != null ]; do
    output="$("$srcdir/spotify_api.sh" "$url_path" "$@")"
    # shellcheck disable=SC2181
    if [ $? != 0 ] || [ "$(jq -r '.error' <<< "$output")" != null ]; then
        echo "$output" >&2
        exit 1
    fi
    url_path="$(get_next)"
    output
done
