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
#  If you're using my code you're welcome to connect with me on LinkedIn
#  and optionally send me feedback to help steer this or other code I publish
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

If <new_playlist_name> is a directory or ends with /, the file is moved into
that directory keeping the same filename (rename to <dir>/<old_filename>)

With optional third arg <subdir> (path-mapped backups): renames under
\$PWD/<subdir>/ and \$PWD/spotify/<subdir>/ instead, invoke from backup base
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<old_playlist_name> <new_playlist_name> [<subdir>]"

help_usage "$@"

min_args 2 "$@"

old="$1"
new="$2"
subdir="${3:-}"

# the replacement of slashes breaks the later logic to test for destination being a directory
#old="$("$srcdir/../spotify/spotify_playlist_to_filename.sh" "$old")"
#new="$("$srcdir/../spotify/spotify_playlist_to_filename.sh" "$new")"

# optional subdir for path-mapped backups: playlists in base/Subdir/, URIs in base/spotify/Subdir/
if [ -n "$subdir" ]; then
    prefix="$subdir/"
    spotify_prefix="spotify/$subdir/"
else
    prefix=""
    spotify_prefix="spotify/"
fi

# if new is a directory or ends in /, treat as directory: rename to same filename under that path
if [[ "$new" == */ ]] || [[ -d "${prefix}$new" ]]; then
    mkdir -p -v "$new"
    new_dest="${new%/}/$old"
    dest_prefix=""
    spotify_dest_prefix="spotify/"
    mkdir -p -v "${spotify_dest_prefix}$new"
else
    new_dest="$new"
    dest_prefix="$prefix"
    spotify_dest_prefix="$spotify_prefix"
fi

# the gitrename function in lib/git.sh has been updated to preserve the new file
# and restore it after the move to then git diff and commit any updates
gitrename "${prefix}$old" "${dest_prefix}$new_dest"

gitrename "${spotify_prefix}$old" "${spotify_dest_prefix}$new_dest"

if [ -f "aggregations/${prefix}$old" ]; then
    gitrename "aggregations/${prefix}$old" "aggregations/${dest_prefix}$new_dest"
fi

if [ -f "${prefix}$old.description" ]; then
    gitrename "${prefix}$old.description" "${dest_prefix}$new_dest.description"
fi

if [ -f "id/${prefix}$old.id.txt" ]; then
    mv -v "id/${prefix}$old.id.txt" "id/${dest_prefix}$new_dest.id.txt"
fi
