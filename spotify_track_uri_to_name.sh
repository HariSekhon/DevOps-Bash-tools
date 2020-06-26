#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-06-25 22:28:51 +0100 (Thu, 25 Jun 2020)
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
Takes Spotify track URIS and converts them to 'Artist - Track names' using the Spotify API

Track URIs are fed via standard input and can accept any of the following forms for convenience:

spotify:track:<alphanumeric_ID>
http://open.spotify.com/track/<alphanumeric_ID>
<alphanumeric_ID>

These IDs are 22 chars, but this is length is not enforced

Useful for saving Spotify playlists in a format that is easier to understand the revision control changes or export to other music systems

Requires \$SPOTIFY_ACCESS_TOKEN in the environment (can generate from spotify_api_token.sh) or will auto generate from \$SPOTIFY_CLIENT_ID and \$SPOTIFY_CLIENT_SECRET if found in the environment

export SPOTIFY_ACCESS_TOKEN=\"\$('$srcdir/spotify_api_token.sh')\"
"

# shellcheck disable=SC1090
. "$srcdir/lib/utils.sh"

help_usage "$@"

url_base="/v1/tracks"

output(){
    jq -r '.tracks[] | [ .artists[].name, "-", .name ] | @tsv' <<< "$output" | tr '\t' ' '
}

while true; do
    ids=""
    for ((i=0; i<50; i++)); do
        read -r -s track_uri || break
        if [[ "$track_uri" =~ ^spotify:local: ]]; then
            track_uri="${track_uri#spotify:local:}"
            track_uri="${track_uri#:}"
            track_uri="${track_uri#:}"
            track_uri="${track_uri%:*}"
            track_uri="${track_uri//+/ }"
            "$srcdir/urldecode.sh" <<< "$track_uri"
            continue
        fi
        if ! [[ "$track_uri" =~ ^(spotify:track:|http://open.spotify.com/track/)?[[:alnum:]]+$ ]]; then
            echo "Invalid track URI provided: $track_uri" >&2
            exit 1
        fi
        track_uri="${track_uri##*[:/]}"
        ids+=",$track_uri"
    done
    if [ -z "$ids" ]; then
        break
    fi
    ids="${ids#,}"
    url_path="$url_base?ids=$ids"
    output="$("$srcdir/spotify_api.sh" "$url_path" "$@")"
    # shellcheck disable=SC2181
    if [ $? != 0 ] || [ "$(jq -r '.error' <<< "$output")" != null ]; then
        echo "$output" >&2
        exit 1
    fi
    output
    sleep 0.1
done
