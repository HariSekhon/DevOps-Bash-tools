#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-07-21 11:36:49 +0100 (Tue, 21 Jul 2020)
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

# shellcheck disable=SC2034
usage_description="
Adds / Modifies track metadata across all MP3 in the directory tree to restructure Audiobooks to be contiguous for Mac's Books.app

If no directory argument is given, works on MP3s under \$PWD

Shows the list of MP3 files and the tags they would be changed to a depth of 1 subdirectory and prompts for confirmation before proceeding for safety

MP3 filenames should be in lexical order before running this
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<dir1> <dir2> ...]"

# shellcheck disable=SC1090
. "$srcdir/lib/utils.sh"

help_usage "$@"

check_bin id3v2

mp3_files="$(for dir in "${@:-$PWD}"; do find "$dir" -maxdepth 2 -iname '*.mp3' || exit 1; done)"

if is_blank "$mp3_files"; then
    echo "No MP3 files found"
    exit 1
fi

echo "List of MP3 files and their metadata track ordering:"

echo

{
    i=0;
    while read -r mp3; do
        [ -n "$mp3" ] || continue
        ((i+=1))
        printf '%s\t%s\n' "$i" "$mp3"
    done
} <<< "$mp3_files"

echo

read -r -p 'Are you happy with this track metadata ordering? (y/N) ' answer

if [ "$answer" != "y" ]; then
    echo "Aborting..."
    exit 1
fi

echo

{
    i=0;
    while read -r mp3; do
        [ -n "$mp3" ] || continue
        ((i+=1))
        echo "setting track order $i on '$mp3'"
        id3v2 --track "$i" "$mp3"
    done
} <<< "$mp3_files"
