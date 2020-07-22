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
Adds / Modifies artist metadata across all mp3 files in the given directories to edit albums or group audiobooks for Mac's Books.app

Shows the list of MP3 files that would be affected before running the metadata update and prompts for confirmation before proceeding for safety
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="\"artist name\" <dir1> [<dir2> ...]"

# shellcheck disable=SC1090
. "$srcdir/lib/utils.sh"

help_usage "$@"

min_args 2 "$@"

check_bin id3v2

artist="$1"

shift || :

mp3_files="$(for dir in "$@"; do find "$dir" -maxdepth 2 -iname '*.mp3' || exit 1; done)"

echo "List of MP3 files to set artist = '$artist':"
echo
echo "$mp3_files"
echo
read -r -p "Are you happy to set the artist metadata on all of the following mp3 files to '$*' (y/N) " answer

if [ "$answer" != "y" ]; then
    echo "Aborting..."
    exit 1
fi

echo

while read -r mp3; do
    echo "setting artist '$artist' on '$mp3'"
    id3v2 --artist "$artist" "$mp3"
done <<< "$mp3_files"
