#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  args: 64OO67Be8wOXn6STqHxexr
#  args: Florence.*
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

# https://developer.spotify.com/documentation/web-api/reference/library/get-users-saved-tracks/

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<curl_options>]"

# shellcheck disable=SC2034
usage_description="
Returns a Spotify user's Saved Tracks

Spotify track URIs can be used as backups to restore a playlist's contents or copying to a new playlist, or combined with spotify_set_track_uris_as_saved.sh

Requires \$SPOTIFY_ID and \$SPOTIFY_SECRET to be defined in the environment

Caveat: due to limitations of the Spotify API, this requires an interactively authorized access token, which you will be prompted for if you haven't already got one in your shell environment. To set up an authorized token for an hour in your current shell, you can run the following command (make sure you don't have an access token in the environment from spotify_api_token.sh otherwise you will get a 401 error):

export SPOTIFY_ACCESS_TOKEN=\"\$(\"$srcdir/spotify_api_token_interactive.sh\")\"
"

# shellcheck disable=SC1090
. "$srcdir/lib/utils.sh"

help_usage "$@"

offset="${OFFSET:-0}"

url_path="/v1/me/tracks?limit=50&offset=$offset"

output(){
    jq -r '.items[] | [.track.uri] | @tsv' <<< "$output"
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
