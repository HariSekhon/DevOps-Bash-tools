#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-07-04 13:14:15 +0100 (Sat, 04 Jul 2020)
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

# shellcheck disable=SC2034
usage_description="
Renames a Spotify playlist in both the \$PWD and \$PWD/spotify/ directories
to keep the Spotify backups in sync
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<playlist_old_name> <playlist_new_name>"

# shellcheck disable=SC1090,SC1091
. "$srcdir/lib/utils.sh"

help_usage "$@"

# shellcheck disable=SC1090,SC1091
. "$srcdir/../.bash.d/git.sh"

rename(){
    local from="$1"
    local to="$2"

    from="$("$srcdir/../spotify/spotify_playlist_to_filename.sh" "$from")"
    to="$("$srcdir/../spotify/spotify_playlist_to_filename.sh" "$to")"

    gitrename "$from" "$to"

    gitrename "spotify/$from" "spotify/$to"
}

rename "$1" "$2"
