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

# https://developer.spotify.com/documentation/web-api/reference/follow/get-followed/

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck disable=SC1090,SC1091
. "$srcdir/lib/spotify.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Takes a list of Spotify Artists in URI format and sets them to be followed

Useful when combined with adjacent script:

    spotify_liked_artists_uri.sh

to automatically follow all artists for which you have liked tracks, or combined with a shell pipeline to only like artists with at least 3 liked tracks:

    spotify_liked_artists_uri.sh | sort | uniq -c | sort -k1nr | grep


$usage_auth_help


Can specify either one or more files with a list of spotify artist URIs, otherwise reads URIs from standard input
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<file1> <file2> ...]"

help_usage "$@"

# defined in lib/spotify.sh
# shellcheck disable=SC2154
url_path="/v1/me/following?type=artist"

export SPOTIFY_PRIVATE=1

spotify_token

count=0

follow_artists(){
    if [ $# -lt 1 ]; then
        echo "Error: no artist IDs passed to follow_artists()" >&2
        exit 1
    fi
    local ids=""
    for id in "$@"; do
        ids+="$id,"
    done
    ids="${ids%,}"
    timestamp "following ${#@} artists"
    "$srcdir/spotify_api.sh" "$url_path&ids=$ids" -X PUT #>/dev/null  # ignore the { "spotify_snapshot": ... } json output
    ((count+=${#@}))
}

add_file_URIs(){
    declare -a ids
    ids=()
    while read -r artist_uri; do
        if is_blank "$artist_uri"; then
            continue
        fi
        if is_local_uri "$artist_uri"; then
            continue
        fi
        id="$(uri_type=artist validate_spotify_uri "$artist_uri")"

        ids+=("$id")

        if [ "${#ids[@]}" -ge 50 ]; then
            follow_artists "${ids[@]}"
            sleep 1
            ids=()
        fi
    done < "$filename"

    if [ "${#ids[@]}" -eq 0 ]; then
        return
    fi
    follow_artists "${ids[@]}"
}

for filename in "${@:-/dev/stdin}"; do
    add_file_URIs "$filename"
done

timestamp "$count artists followed"
