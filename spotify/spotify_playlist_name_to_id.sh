#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  args: "My Shazam Tracks" | tee /dev/stderr | spotify_playlist_id_to_name.sh
#
#  Author: Hari Sekhon
#  Date: 2020-07-03 00:25:24 +0100 (Fri, 03 Jul 2020)
#
#  https://github.com/HariSekhon/DevOps-Bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/HariSekhon
#

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck disable=SC1090,SC1091
. "$srcdir/lib/spotify.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Uses Spotify API to translate a Spotify public playlist name to ID

If a Spotify playlist ID is given, returns it as is (this is for coding convenience when calling from other scripts)

Needed by several other adjacent spotify tools


$usage_playlist_help

$usage_auth_help
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<playlist> [<curl_options>]"

help_usage "$@"

#if is_mac; then
#    awk(){
#        command gawk "$@"
#    }
#fi

# causes way too many random problems to allow partial substring matching, wastes time debugging, better to fail
export SPOTIFY_PLAYLIST_EXACT_MATCH=1

playlist_name_to_id(){
    local playlist_name="$1"
    shift || :
    # if it's not a playlist id, scan all playlists and take the ID of the first matching playlist name
    if is_spotify_playlist_id "$playlist_name"; then
        echo "$playlist_name"
    else
        # If we've auto-completed a playlist name from the filename, replace the unicode slashes with the real ones
        if [ -f "$playlist_name" ]; then
            playlist_name="$("$srcdir/spotify_filename_to_playlist.sh" <<< "$playlist_name")"
        fi
        # works but could get needlessly complicated to escape all possible regex special chars, switching to partial string match instead
        #playlist_regex="${playlist_id//\//\\/}"
        #playlist_regex="${playlist_regex//\(/\\(}"
        #playlist_regex="${playlist_regex//\)/\\)}"
                       #awk "BEGIN{IGNORECASE=1} /${playlist_regex//\//\\/}/ {print \$1; exit}" || :)"
        playlist_id="$(SPOTIFY_PLAYLISTS_ALL=1 "$srcdir/spotify_playlists.sh" "$@" |
                        if [ "${SPOTIFY_PLAYLIST_EXACT_MATCH:-}" ]; then
                            # do not tr [:upper:] [:lower:] as this invalidates the ID which is case insensitive
                            # save last case sensitive setting, ignore return code which will error if not already set
                            last_nocasematch="$(shopt -p nocasematch || :)"
                            shopt -s nocasematch
                            while read -r id name; do
                                if [[ "$name" = "$playlist_name" ]]; then
                                   echo "$id"
                                   break
                                fi
                            done
                            # restore last case sensitive setting
                            eval "$last_nocasematch"
                        else
                            grep -Fi -m1 "$playlist_name" |
                            awk '{print $1}'
                        fi || :
        )"
        if is_blank "$playlist_id"; then
            echo "Error: failed to find playlist ID matching given playlist name '$playlist_name'" >&2
            exit 1
        fi
        echo "$playlist_id"
    fi
}

spotify_token

if [ $# -gt 0 ]; then
    playlist_name="$1"
    shift || :
    playlist_name_to_id "$playlist_name" "$@"
else
    while read -r playlist_name; do
        playlist_name_to_id "$playlist_name" "$@"
    done
fi
