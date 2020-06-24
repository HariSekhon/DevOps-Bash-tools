#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  args: 64OO67Be8wOXn6STqHxexr
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
usage_args="<playlist_id> [<curl_options>]"

# shellcheck disable=SC2034
usage_description="
Returns track names for the spotify playlist for given playlist id argument or \$SPOTIFY_PLAYLIST (get this from spotify_playlists.sh)

Requires \$SPOTIFY_ACCESS_TOKEN in the environment (can generate from spotify_api_token.sh) or will auto generate from \$SPOTIFY_CLIENT_ID and \$SPOTIFY_CLIENT_SECRET if found in the environment

export SPOTIFY_ACCESS_TOKEN=\"\$('$srcdir/spotify_api_token.sh')\"
"

# shellcheck disable=SC1090
. "$srcdir/lib/utils.sh"

help_usage "$@"

playlist_id="${1:-${SPOTIFY_PLAYLIST:-}}"

if [ -z "$playlist_id" ]; then
    usage "playlist id not defined"
fi

offset="${OFFSET:-0}"

url_path="/v1/playlists/$playlist_id/tracks?limit=50&offset=$offset"

output(){
    #jq -r '.items[] | [.id, .name] | @tsv' <<< "$output"
    jq -r '.items[].track | [.artists[].name, "-", .name] | @tsv' <<< "$output" | tr '\t' ' '
}

get_next(){
    jq -r '.next' <<< "$output"
}

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
