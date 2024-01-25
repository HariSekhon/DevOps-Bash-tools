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
Commits and Renames a Spotify playlist

When Spotify playlist names change and you want to commit the updates which were downloaded to a new non-committed playlist file,
this script will copy the new playlist file given as the first argument over the old playlist filen given as the second argument,
then commit the original playlist file to check the history for removals using spotify_commit_playlists.sh, and then rename the old
playlist file to the new playlist file to align with the spotify_backup*.sh exports in future
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<playlist_new_name> <playlist_existing_name>"

# shellcheck disable=SC1090,SC1091
. "$srcdir/lib/utils.sh"

help_usage "$@"

commit_rename(){
    mv -vf -- "$1" "$2"
    cd spotify
    mv -vf -- "$1" "$2"
    cd ..

    "$srcdir/spotify_commit_playlists.sh" "$2"

    "$srcdir/spotify_rename_playlist_files.sh" "$2" "$1"
}

if [ $# -gt 0 ]; then
    commit_rename "$1" "$2"
else
    git st --porcelain |
    grep '^??' |
    cut -d" " -f 2- |
    sed 's/spotify\///'|
    sort -u |
    while read -r filename; do
        if [ -f "${filename// /_}" ] &&
           [ -f "spotify/${filename// /_}" ]; then
            commit_rename "$filename" "${filename// /_}"
            read -r -p "Press Enter to continue"
        fi
    done
fi
