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

# shellcheck disable=SC1090,SC1091
. "$srcdir/lib/utils.sh"

# shellcheck disable=SC1090,SC1091
. "$srcdir/../.bash.d/git.sh"

# shellcheck disable=SC2034
usage_description="
Renames a Spotify playlist in both the \$PWD and \$PWD/spotify/ directories
to keep the Spotify backups in sync
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<old_playlist_name> <new_playlist_name>"

help_usage "$@"

num_args 2 "$@"

old="$1"
new="$2"

old="$("$srcdir/../spotify/spotify_playlist_to_filename.sh" "$old")"
new="$("$srcdir/../spotify/spotify_playlist_to_filename.sh" "$new")"

# the gitrename function in lib/git.sh has been updated to preserve the new file
# and restore it after the move to then git diff and commit any updates
gitrename "$old" "$new"

gitrename "spotify/$old" "spotify/$new"

if [ -f "agregations/$old" ]; then
    gitrename "aggregations/$old" "aggregations/$new"
fi

if [ -f "$old.description" ]; then
    gitrename "$old.description" "$new.description"
fi

if [ -f "id/$old.id.txt" ]; then
    mv -v "id/$old.id.txt" "id/$new.id.txt"
fi
