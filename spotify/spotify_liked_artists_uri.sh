#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-10-23 21:06:46 +0100 (Fri, 23 Oct 2020)
#
#  https://github.com/HariSekhon/DevOps-Bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/HariSekhon
#

# https://developer.spotify.com/documentation/web-api/reference/library/get-users-saved-tracks/

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck disable=SC1090,SC1091
. "$srcdir/lib/spotify.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Returns the artist URIs of all artists in Liked Songs

Useful for piping to spotify_follow_artists.sh

To see the list of Liked artists by name, it's faster to pipeline all the URIs to spotify_uri_to_name.sh which batches translations in groups of 50, then sort and count at the very end by name (it's also potentially more accurate where more than one URI converts to the same artist name), or just run:

    spotify_liked_artists.sh

$usage_auth_help
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<curl_options>]"

help_usage "$@"

# defined in lib/spotify.sh
# shellcheck disable=SC2154
# max 50 artists per request
url_path="/v1/me/tracks?limit=$limit&offset=$offset"

output(){
    #jq -r . <<< "$output"
    jq -r '.items[].track.artists[].uri' <<< "$output"
}

export SPOTIFY_PRIVATE=1

spotify_token

while not_null "$url_path"; do
    output="$("$srcdir/spotify_api.sh" "$url_path" "$@")"
    #die_if_error_field "$output"
    url_path="$(get_next "$output")"
    output
done
