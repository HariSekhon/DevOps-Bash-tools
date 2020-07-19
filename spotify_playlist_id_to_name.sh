#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#  args: 2ddv4fdbsD7WOnmY30g40i | tee /dev/stderr | spotify_playlist_name_to_id.sh "`cat`"
#
#  Author: Hari Sekhon
#  Date: 2020-07-03 00:25:24 +0100 (Fri, 03 Jul 2020)
#
#  https://github.com/harisekhon/bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/harisekhon
#

# https://developer.spotify.com/documentation/web-api/reference/playlists/get-playlist/

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck disable=SC2034
usage_description="
Uses Spotify API to translate a Spotify public playlist ID to a name

If a spotify playlist name is given instead of an ID, returns it as is

Needed by several other adjacent spotify tools

Caveat: due to limitations of the Spotify API, this only works for public playlists
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<playlist> [<curl_options>]"

# shellcheck disable=SC1090
. "$srcdir/lib/utils.sh"

help_usage "$@"

min_args 1 "$@"

playlist_id="$1"
shift || :

# if it's not a playlist id, scan all playlists and take the ID of the first matching playlist name
if [[ "$playlist_id" =~ ^[[:alnum:]]{22}$ ]]; then
    playlist_name="$("$srcdir/spotify_api.sh" "/v1/playlists/$playlist_id" "$@" |
                jq -r '.name' || :)"
    if [ -z "$playlist_name" ]; then
        echo "Error: failed to find playlist name matching ID '$playlist_id'" >&2
        exit 1
    fi
    echo "$playlist_name"
else
    echo "$playlist_id"
fi
