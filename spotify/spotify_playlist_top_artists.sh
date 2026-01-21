#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  args: "Favourites 💯 😎"
#  args: 3iRkPfmGAPH9zOrOwPOibk
#
#  Author: Hari Sekhon
#  Date: 2026-01-20 23:02:35 -0500 (Tue, 20 Jan 2026)
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
Returns the top artists for a given Spotify playlist by counting unique track names for each artist

If HariSekhon/Spotify-tools is in the \$PATH it uses normalize_tracknames.pl for greater accuracy to
collapse multiple versions such as Radio Edit and Album Version to only count that same song once

Playlist argument can be a playlist name or a playlist ID (get this from spotify_playlists.sh)

\$SPOTIFY_PLAYLIST can be used from environment if no first argument is given


Output format:

<unique_track_count> <artist>
<unique_track_count> <artist2>


$usage_playlist_help

$usage_auth_help
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<playlist> [<curl_options>]"

help_usage "$@"

playlist_id="${1:-${SPOTIFY_PLAYLIST:-}}"

shift || :

if is_blank "$playlist_id"; then
    usage "playlist not defined"
fi

spotify_token

playlist_id="$("$srcdir/spotify_playlist_name_to_id.sh" "$playlist_id" "$@")"

# defined in lib/spotify.sh
# shellcheck disable=SC2154
url_path="/v1/playlists/$playlist_id/tracks?limit=100&offset=$offset"

print_output(){
    jq -r '
      .items[]
      | .track
      | select(.name and .artists)
      | .name as $track
      | .artists[]
      | [.name, $track]
      | @tsv
    ' <<< "$output"
}

while not_null "$url_path"; do
    output="$("$srcdir/spotify_api.sh" "$url_path" "$@")"
    #die_if_error_field "$output"
    url_path="$(get_next "$output")"
    print_output
    # slow down a bit to try to reduce hitting Spotify API rate limits and getting HTTP 429 Too Many Requests on large playlists
    #sleep 0.1
done |
# if HariSekhon/Spotify-tools is in the \$PATH, use this to deduplicate variations of the same track
if type -P normalize_tracknames.pl &>/dev/null; then
    normalize_tracknames.pl
else
    cat
fi |
sort -u |
if [ -n "${DEBUG_ARTIST_TRACKS:-}" ]; then
    cat
else
    cut -f1 |
    sed '/^[[:space:]]*$/d' |
    sort |
    uniq -c |
    sort -nr
fi
