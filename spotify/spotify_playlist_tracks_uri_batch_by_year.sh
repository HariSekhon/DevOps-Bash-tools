#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  args: "Upbeat & Sexual Pop"
#  args: 64OO67Be8wOXn6STqHxexr
#
#  Author: Hari Sekhon
#  Date: 2026-02-10 23:44:07 -0300 (Tue, 10 Feb 2026)
#
#  https://github.com/HariSekhon/DevOps-Bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn
#  and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/HariSekhon
#

# https://developer.spotify.com/documentation/web-api/reference/playlists/get-playlist/

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck disable=SC1090,SC1091
. "$srcdir/lib/spotify.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Returns all track URIs from the given Spotify playlist(s) grouped by year or decade

Copies each batch to the clipboard, prints to stdout, and prompts to continue
before printing the next batch

Set the environment variable TRACK_URIS_BY_DECADE to any value for decade batching

Useful for filtering tracks to add to my best of each year or decade playlists

Playlist argument can be a playlist name or ID (see spotify_playlists.sh)

$usage_playlist_help

$usage_auth_help
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<playlist> [<playlist2> <playlist3>]"

help_usage "$@"

if [ $# -eq 0 ]; then
    usage "playlist not defined"
fi

spotify_token

tmpfile="$(mktemp)"
trap_cmd "rm -f \"$tmpfile\""

# collect year/decade + URI pairs
collect_output() {
    jq -r '
        .items[]
        | select(.track?.uri)
        | .track as $t
        | ($t.album.release_date // "") as $rd
        | select($rd | length >= 4)
        | ($rd[0:4]) as $year
        | select($year | test("^[0-9]{4}$"))
        | "\($year)\t\($t.uri)"
    ' <<< "$output" >> "$tmpfile"
}

process_playlist(){
    local playlist="$1"
    timestamp "Processing playlist: $playlist"
    playlist_id="$("$srcdir/spotify_playlist_name_to_id.sh" "$playlist")"

    # $offset defined in lib/spotify.sh
    # shellcheck disable=SC2154
    url_path="/v1/playlists/$playlist_id/tracks?limit=100&offset=$offset"

    while not_null "$url_path"; do
        output="$("$srcdir/spotify_api.sh" "$url_path")"
        url_path="$(get_next "$output")"
        collect_output
        # slow down a bit to try to reduce hitting Spotify API rate limits and getting 429 errors on large playlists
        sleep 0.1
    done
}

for arg; do
    process_playlist "$arg"
done
echo

if [ -n "${TRACK_URIS_BY_DECADE:-}" ]; then
    grouped="$(
        awk -F'\t' '
            {
                decade = substr($1,1,3) "0s"
                print decade "\t" $2
            }
        ' "$tmpfile" |
        sort -u -k2,2 |
        sort -k1,1 -k2,2
    )"
else
    grouped="$(
        sort -u -k2,2 "$tmpfile" |
        sort -k1,1 -k2,2
    )"
fi

current=""

batchfile="$(mktemp)"
trap_cmd "rm -f \"$tmpfile\" \"$batchfile\""

while IFS=$'\t' read -r label uri; do
    # when we move to the next year or decade, dump the current batchfile and reset it for the next batch
    if [ "$label" != "$current" ] && [ -n "$current" ]; then
        {
            echo "=== $current ==="
            echo
            tee >( "$srcdir/../bin/copy_to_clipboard.sh" ) < "$batchfile"
            echo
        } | less -F
        printf "Press ENTER to continue..." >&2
        # read < tty avoids reading from the loop stdin but requires interactive TTY support
        # otherwise we need to do the trick from my doc here which is a bit more exec tricky:
        #
        # https://github.com/HariSekhon/Knowledge-Base/blob/main/bash.md#wait-for-a-terminal-prompt-from-inside-a-while-loop
        #
        # need to handle SIGINT explicitly to allow Control-C from this read < tty
        trap 'echo; exit 130' INT
        read -r _ < /dev/tty || exit 130
        echo
        # clear batchfile
        : > "$batchfile"
    fi

    current="$label"
    printf '%s\n' "$uri" >> "$batchfile"
done <<< "$grouped"

# Final batch
if [ -s "$batchfile" ]; then
    {
        echo
        echo "=== $current ==="
        echo
        tee >( "$srcdir/../bin/copy_to_clipboard.sh" ) < "$batchfile"
        echo
    } | less -F
fi
