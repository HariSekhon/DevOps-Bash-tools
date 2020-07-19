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

# https://developer.spotify.com/documentation/web-api/reference/playlists/get-a-list-of-current-users-playlists/

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<curl_options>]"

# shellcheck disable=SC2034
usage_description="
Returns the list of Spotify private playlists for your access token

THe spotify user is inferred from the access token

Output Format:

<playlist_id>   <playlist_name>

Requires \$SPOTIFY_ID and \$SPOTIFY_SECRET to be defined in the environment

Caveat: due to limitations of the Spotify API, this requires an interactive web authorization pop-up or
\$SPOTIFY_ACCESS_TOKEN in the environment:

export SPOTIFY_ACCESS_TOKEN=\"\$(\"$srcdir/spotify_api_token_interactive.sh\")\"

If you have exported a non-authorized \$SPOTIFY_ACCESS_TOKEN in your environment (eg. from spotify_api_token.sh),
then this script will fail with a 401 unauthorized error
"

# shellcheck disable=SC1090
. "$srcdir/lib/utils.sh"

help_usage "$@"

offset="${OFFSET:-0}"

# /v1/me/playlists gets an authorization error and '/v1/users/me/playlists' returns the wrong user, an actual literal user called 'me'
url_path="/v1/me/playlists?limit=50&offset=$offset"

output(){
    jq -r ".items[] | select(.public != true) | [.id, .name] | @tsv" <<< "$output"
}

get_next(){
    jq -r '.next' <<< "$output"
}

if [ -z "${SPOTIFY_ACCESS_TOKEN:-}" ]; then
    SPOTIFY_ACCESS_TOKEN="$("$srcdir/spotify_api_token_interactive.sh")"
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
