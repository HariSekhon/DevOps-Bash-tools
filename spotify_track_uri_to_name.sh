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
Takes Spotify track URIs and converts them to 'Artist - Track' names using the Spotify API

Track URIs are fed via standard input and can accept any of the following forms for convenience:

spotify:track:<alphanumeric_ID>
http://open.spotify.com/track/<alphanumeric_ID>
<alphanumeric_ID>

These IDs are 22 chars, but this is length is not enforced in case the Spotify API changes

Output format:

Artist - Track

or if \$SPOTIFY_CSV environment variable is set then:

\"Artist\",\"Track\"

Useful for saving Spotify playlists in a format that is easier to understand, revision control changes or export to other music systems

Uses the Spotify bulk track API if there are no local track references in a playlist, otherwise falls back to individual track lookups
in order to preserve the correct playlist ordering between Spotify and local tracks

Requires \$SPOTIFY_CLIENT_ID and \$SPOTIFY_CLIENT_SECRET to be defined in the environment
"

# https://developer.spotify.com/documentation/web-api/reference/tracks/get-track/

# https://developer.spotify.com/documentation/web-api/reference/tracks/get-several-tracks/

# shellcheck disable=SC1090
. "$srcdir/lib/utils.sh"

help_usage "$@"

url_base="/v1/tracks"

if [ -z "${SPOTIFY_ACCESS_TOKEN:-}" ]; then
    SPOTIFY_ACCESS_TOKEN="$("$srcdir/spotify_api_token.sh")"
    export SPOTIFY_ACCESS_TOKEN
fi

track_by_track(){
    while true; do
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
        track_id="${track_uri##*[:/]}"
        url_path="$url_base/$track_id"
        output="$("$srcdir/spotify_api.sh" "$url_path" "$@")"
        # shellcheck disable=SC2181
        if [ $? != 0 ] || [ "$(jq -r '.error' <<< "$output")" != null ]; then
            echo "$output" >&2
            exit 1
        fi
        output
        sleep 0.1
    done
}

track_by_bulk(){
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
                ((i-=1))
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
        output_bulk
        sleep 0.1
    done
}

output(){
    if [ -n "${SPOTIFY_CSV:-}" ]; then
        jq -r '[([.artists[].name] | join(",")), .name] | @csv'
    else
        jq -r '[([.artists[].name] | join(",")), "-", .name] | @tsv'
    fi <<< "$output" |
    clean_output
}

output_bulk(){
    if [ -n "${SPOTIFY_CSV:-}" ]; then
        jq -r '.tracks[] | [([.artists[].name] | join(",")), .name] | @csv'
    else
        jq -r '.tracks[] | [([.artists[].name] | join(",")), "-", .name] | @tsv'
    fi <<< "$output" |
    clean_output
}

clean_output(){
    tr '\t' ' ' |
    sed '
        s/^[[:space:]]*-//;
        s/^[[:space:]]*//;
        s/[[:space:]]*$//
    '
}

# must slurp in to memory and check all track URIs for local references before knowing if it's safe to use bulk track API
track_uris="$(cat)"

if grep -q 'spotify:local:' <<< "$track_uris"; then
    # in order to preserve the correct playlist ordering
    track_by_track "$@" <<< "$track_uris"
else
    track_by_bulk "$@" <<< "$track_uris"
fi
