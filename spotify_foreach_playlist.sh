#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-06-24 16:33:04 +0100 (Wed, 24 Jun 2020)
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
usage_args="<command to execute per playlist> [<spotify_user> [<curl_options>]"

# shellcheck disable=SC2034
usage_description="
Executes a command per Spotify playlist for a given user

The command must be quoted as the first argument and is templated, replacing the placeholders {playlist} and {playlist_id} in the command string

Useful for combining with other spotify_*.sh scripts, such as downloading all the 'Artist - Track' names or all the Spotify URIs as backups

Requires \$SPOTIFY_USER be set in the environment or else given as the second arg

Requires \$SPOTIFY_ACCESS_TOKEN in the environment (can generate from spotify_api_token.sh) or will auto generate from \$SPOTIFY_CLIENT_ID and \$SPOTIFY_CLIENT_SECRET if found in the environment

export SPOTIFY_ACCESS_TOKEN=\"\$('$srcdir/spotify_api_token.sh')\"
"

# shellcheck disable=SC1090
. "$srcdir/lib/utils.sh"

help_usage "$@"

if [ $# -lt 1 ]; then
    usage
fi

command_template="$1"
shift

"$srcdir/spotify_playlists.sh" "$@" |
while read -r playlist_id playlist; do
    printf '%s\t' "$playlist"
    cmd="${command_template//\{playlist_id\}/$playlist_id}"
    cmd="${cmd//\{playlist\}/\"$playlist\"}"
    # handle danger
    # this works, tested on Ke$ha playlist and `echo injected`
    cmd="${cmd//$/\\$}"
    cmd="${cmd//\`/}"
    eval "$cmd"
done
