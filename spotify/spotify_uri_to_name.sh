#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  args: ../../playlists/spotify/Rocky
#
#  Author: Hari Sekhon
#  Date: 2020-06-25 22:28:51 +0100 (Thu, 25 Jun 2020)
#
#  https://github.com/HariSekhon/DevOps-Bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/HariSekhon
#

# https://developer.spotify.com/documentation/web-api/reference/tracks/get-several-tracks/
#
# https://developer.spotify.com/documentation/web-api/reference/albums/get-several-albums/
#
# https://developer.spotify.com/documentation/web-api/reference/artists/get-several-artists/

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck disable=SC1090,SC1091
. "$srcdir/lib/spotify.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Takes Spotify URIs and converts them to Track, Album or Artist names using the Spotify API

Spotify URIs are read from file arguments or standard input and can accept any of the following forms for convenience:

spotify:<type>:<alphanumeric_ID>
http://open.spotify.com/<type>/<alphanumeric_ID>
<alphanumeric_ID>

where <type> is track / episode / album / artist

These IDs are 22 chars, but this is length is not enforced in case the Spotify API changes

Output format (depending on whether it's a track, an album or an artist URI):

Artist - Track
Artist - Album
Artist

or if \$SPOTIFY_CSV environment variable is set then:

\"Artist\",\"Track\"
\"Artist\",\"Album\"
\"Artist\"

Useful for saving Spotify playlists in a format that is easier to understand, revision control changes or export to other music systems

The first argument that doesn't correspond to a file and all subsequent arguements are fed as-is to curl as options


$usage_auth_help
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<files>] [<curl_options>]"

help_usage "$@"

# try to avoid hitting HTTP 429 Too Many Requests as this leads to long ban periods of ~14 hours
# throttle by this many seconds between bulk query requests
sleep_secs="0.5"

declare -a curl_options
curl_options=()

spotify_token

infer_uri_type(){
    local uri="$1"
    if [[ "$uri" =~ ^spotify:(track|album|artist|episode): ]]; then
        echo "${BASH_REMATCH[1]}"
    elif [[ "$uri" =~ ^https?://open.spotify.com/(track|album|artist|episode)/ ]]; then
        echo "${BASH_REMATCH[1]}"
    else
        # default fallback
        echo "${SPOTIFY_URI_TYPE:-track}"
    fi
}

convert(){
    # associative array: type -> comma-separated IDs
    declare -A batch_ids
    declare -A batch_counts

    while read -r uri || [ -n "$uri" ]; do
        [ -z "$uri" ] && continue

        # skip local URIs first
        if is_local_uri "$uri"; then
            # flush all current batches before outputting local
            for t in "${!batch_ids[@]}"; do
                query_bulk_type "$t" "${batch_ids[$t]}"
                batch_ids["$t"]=""
            done
            output_local_uri "$uri"
            continue
        fi

        # determine type of URI
        type="$(infer_uri_type "$uri")"
        id="$(validate_spotify_uri "$uri")"

        # append to batch
        batch_ids["$type"]+="$id,"
        batch_counts["$type"]=$(( ${batch_counts["$type"]:-0} + 1 ))

        # flush batch if it reaches 50
        if [ "${batch_counts[$type]}" -ge 50 ]; then
            query_bulk_type "$type" "${batch_ids[$type]}"
            batch_ids["$type"]=""
            batch_counts["$type"]=0
        fi
    done

    # flush remaining batches
    for t in "${!batch_ids[@]}"; do
        [ -n "${batch_ids[$t]}" ] && query_bulk_type "$t" "${batch_ids[$t]}"
    done
}

# bulk query the correct endpoint per type to reduce the number of queries and to
# both improve performance and try to avoid the dredded HTTP 429 Too Many Requests 14 hour ban
query_bulk_type(){
    local type="$1"
    local ids_csv="${2%,}"  # remove trailing comma
    [ -z "$ids_csv" ] && return

    local url_base="/v1/${type}s"

    if [ "${#curl_options[@]}" -gt 0 ]; then
        "$srcdir/spotify_api.sh" "$url_base?ids=$ids_csv" "${curl_options[@]}"
    else
        "$srcdir/spotify_api.sh" "$url_base?ids=$ids_csv"
    fi |
    output  # pipe into jq output()
    sleep "$sleep_secs"
}

output_local_uri(){
    local uri="$1"
    if [[ "$uri" =~ ^spotify:local: ]]; then
        uri="${uri#spotify:local:}"
        artist="${uri%%:*}"
        uri="${uri#*:}"
        uri="${uri#*:}"
        uri="${uri%:*}"
    elif [[ "$uri" =~ open.spotify.com/local/ ]]; then
        uri="${uri#http://open.spotify.com/local/}"
        artist="${uri%%/*}"
        uri="${uri#*/}"
        uri="${uri#*/}"
        uri="${uri%/*}"
    else
        echo "Unrecognized track URI format: $uri"
        exit 1
    fi
    track="${uri//+/ }"
    if not_blank "$artist"; then
        artist="${artist//+/ }"
        track="$artist - $track"
    fi
    "$srcdir/../bin/urldecode.sh" <<< "$track"
}

# This breaks on playlists with mixed URI types such as track + episode in my Love Island playlist so
# push this logic out of bash and to jq where it can be handled in a better unified way
#
#output(){
#    if [[ "$output" =~ \"(tracks|albums|artists|episodes)\"[[:space:]]*:[[:space:]]+\[[[:space:]]*null[[:space:]]*\] ]]; then
#        echo "no matching $uri_type URI found - did you specify an incorrect URI or wrong \$SPOTIFY_URI_TYPE for that URI?" >&2
#        return
#    fi
#    local conversion="@tsv"
#    if not_blank "${SPOTIFY_CSV:-}"; then
#        conversion="@csv"
#    fi
#    if [ "$uri_type" = track ]; then
#        output_artist_item
#    elif [ "$uri_type" = artist ]; then
#        jq -r ".${uri_type}s[] | [([.name] | join(\", \"))] | $conversion"
#    elif [ "$uri_type" = album ]; then
#        output_artist_item
#    else
#        echo "URI type '$uri' parsing not implemented" >&2
#        exit 1
#    fi <<< "$output" |
#    clean_output
#}

# Handled in unified output() function now depending on if fields are detected in jq
#
#output_artist_item(){
#    if not_blank "${SPOTIFY_CSV:-}"; then
#        # some tracks come out with blank artists and track name, skip these using select(name != "") filter to avoid blank lines
#        # unfortunately some tracks actually do come out with blank artist and track name, this must be a bug inside Spotify, but
#        # filtering it like this throws off the line counts verification and also the track might be blank but the artist might not be
#        #jq -r ".${uri_type}s[] | select(.name != \"\") | [([.artists[].name] | join(\", \")), .name] | $conversion"
#        jq -r ".${uri_type}s[] | [([.artists[].name] | join(\", \")), .name] | $conversion"
#    else
#        #jq -r ".${uri_type}s[] | select(.name != \"\") | [([.artists[].name] | join(\", \")), \"-\", .name] | $conversion"
#        jq -r ".${uri_type}s[] | [([.artists[].name] | join(\", \")), \"-\", .name] | $conversion"
#    fi
#}

output(){
    local conversion="@tsv"
    if not_blank "${SPOTIFY_CSV:-}"; then
        conversion="@csv"
    fi

    jq -r '
    # 1) Playlist items
    (
      .tracks?
      | select(type == "object")
      | .items[]?
      | (.track // .episode)
      | select(. != null)
    ),

    # 2) Bulk tracks
    (
      .tracks?
      | select(type == "array")
      | .[]?
    ),

    # 3) Bulk episodes
    (
      .episodes[]?
    ),

    # 4) Single track / episode object
    (
      select(type == "object" and (.type == "track" or .type == "episode"))
    )

    | if .type == "track" then
        [
          (.artists | map(.name) | join(", ")),
          "-",
          .name
        ]
      elif .type == "episode" then
        [
          .show.name,
          "-",
          .name
        ]
      else
        empty
      end
    | '"$conversion"'
    ' |
    clean_output
}
export -f output

clean_output(){
    tr '\t' ' ' |
    sed '
        s/^[[:space:]]*-//;
        s/^[[:space:]]*//;
        s/[[:space:]]*$//
    '
}

files=()

for filename in "$@"; do
    if [ -f "$filename" ]; then
        files+=("$filename")
        shift || :
    else
        break
    fi
done

if [ $# -gt 0 ]; then
    curl_options=("$@")
fi

if [ -n "${files[*]:-}" ]; then
    for filename in "${files[@]}"; do
        convert < "$filename"
    done
else
    convert  # read from stdin
fi
