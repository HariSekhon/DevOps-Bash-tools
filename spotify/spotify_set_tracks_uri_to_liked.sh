#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  args: ../playlists/spotify/Starred | spotify_uri_to_name.sh
#  args: ../playlists/spotify/Starred | tee /dev/stderr | spotify_uri_to_name.sh
#  args: ../playlists/spotify/Starred
#
#  Author: Hari Sekhon
#  Date: 2020-07-20 00:13:30 +0100 (Mon, 20 Jul 2020)
#
#  https://github.com/HariSekhon/DevOps-Bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/HariSekhon
#

# https://developer.spotify.com/documentation/web-api/reference/library/save-tracks-user/

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck disable=SC1090,SC1091
. "$srcdir/lib/spotify.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Sets the given list of Spotify track URIs to Liked Songs via the Spotify API

Track URIs can be given in the form of a file argument or passed via standard input

Sample use cases:
- convert Spotify's previous Starred tracks to Liked Songs (Spotify change Starred a normal playlist and created the new Liked Songs)
- mark all the songs of your favourite playlists as Liked Songs

spotify_set_tracks_uri_to_liked.sh Starred

Outputs the URIs it has marked as Liked Songs so that you can track the progress.
You can combine this with spotify_uri_to_name.sh to get human readable progress, eg:

spotify_set_tracks_uri_to_liked.sh Starred | spotify_uri_to_name.sh

for debugging to see both the URIs processed and the human readable names you can do:

spotify_set_tracks_uri_to_liked.sh Starred | tee /dev/stderr | spotify_uri_to_name.sh


$usage_auth_help
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<filename> [<curl_options>]"

help_usage "$@"

url_path="/v1/me/tracks?ids="

# requires authorized token
export SPOTIFY_PRIVATE=1

spotify_token

declare -a ids
ids=()

set_to_liked(){
    local ids
    # join array arg on commas
    { local IFS=','; ids="$*"; }
    if [ -z "$ids" ]; then
        return
    fi
    "$srcdir/spotify_api.sh" "$url_path${ids}" -X PUT
    tr ',' '\n' <<< "$ids"
}

if [ $# -gt 0 ]; then
    if [ -f "$1" ]; then
        filename="$1"
        shift || :
    else
        echo "first argument is not a present file, reading from stdin" >&2
    fi
else
    filename=/dev/stdin
fi

while read -r track_uri; do
    if is_blank "$track_uri"; then
        continue
    fi
    if is_local_uri "$track_uri"; then
        continue
    fi
    id="$(validate_spotify_uri "$track_uri")"

    ids+=("$id")

    if [ "${#ids[@]}" -ge 50 ]; then
        set_to_liked "${ids[@]}"
        ids=()
    fi
done < "$filename"

set_to_liked "${ids[@]}"
