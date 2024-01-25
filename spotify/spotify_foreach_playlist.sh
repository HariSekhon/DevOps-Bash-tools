#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-06-24 16:33:04 +0100 (Wed, 24 Jun 2020)
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
Executes a command per Spotify playlist for a given user

The command must be quoted as the first argument and is templated, replacing the placeholders {playlist} and {playlist_id} in the command string

Useful for combining with other spotify_*.sh scripts, such as downloading all the 'Artist - Track' names or all the Spotify URIs as backups

WARNING: do not run any command reading from standard input, otherwise it will consume the playlist id/names and exit after the first iteration

Requires \$SPOTIFY_USER be set in the environment or else given as the second arg

$usage_playlist_help

$usage_auth_help


Examples:

./spotify_foreach_playlist.sh './spotify_playlist_tracks.sh {playlist_id} > playlists/{playlist}.txt' harisekhon

./spotify_foreach_playlist.sh './spotify_playlist_tracks_uri.sh {playlist_id} > playlist-backups/{playlist}.txt' harisekhon

(see spotify_backup_playlists.sh for an even better implementation of this above one liner using this script)

"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<command to execute per playlist> [<spotify_user> [<curl_options>]"

help_usage "$@"

min_args 1 "$@"

command_template="$1"
shift || :

spotify_token

"$srcdir/spotify_playlists.sh" "$@" |
while read -r playlist_id playlist; do
    if is_blank "${SPOTIFY_FOREACH_NO_PRINT_PLAYLIST_NAME:-}"; then
        printf '%s\t' "$playlist"
    fi
    # handle danger - done at playlist level not command level because we need late command evaluation in spotify_backup_playlists.sh
    # this works, tested on Ke$ha playlist and `echo injected`
    playlist="${playlist//$/\\$}"
    playlist="${playlist//\`/}"
    cmd="${command_template//\{playlist_id\}/$playlist_id}"
    cmd="${cmd//\{playlist\}/$playlist}"
    eval "$cmd"
    if is_blank "${SPOTIFY_FOREACH_NO_NEWLINE:-}"; then
        printf '\n'
    fi
done
