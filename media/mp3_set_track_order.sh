#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-07-21 11:36:49 +0100 (Tue, 21 Jul 2020)
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
. "$srcdir/lib/mp3.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Add / Modify track number metadata across all MP3 files in the given directories to restructure audiobooks to be contiguous for Mac's Books.app

$mp3_usage_behaviour_msg

MP3 filenames should be in lexical order before running this
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<dir1> <dir2> ...]"

help_usage "$@"

check_bin id3v2

# used to pipe file list inline which is more comp sci 101 correct but that could create a race condition on second
# evaluation of file list changing after confirmation prompt, and RAM is cheap, so better to use a static list of files
# stored in ram and operate on that since it'll never be that huge anyway

mp3_files="$(get_mp3_files "${@:-$PWD}")"

echo "List of MP3 files and their metadata track ordering:"

echo

total=0

while read -r mp3; do
    [ -n "$mp3" ] || continue
    ((total+=1))
done <<< "$mp3_files"

{
    position=0;
    while read -r mp3; do
        [ -n "$mp3" ] || continue
        ((position+=1))
        printf '%s\t%s\n' "$position/$total" "$mp3"
    done
} <<< "$mp3_files"

echo

read -r -p 'Are you happy with this track metadata ordering? (y/N) ' answer

check_yes "$answer"

echo

{
    position=0;
    while read -r mp3; do
        [ -n "$mp3" ] || continue
        ((position+=1))
        echo "setting track order $position/$total on '$mp3'"
        id3v2 --track "$position/$total" "$mp3"
    done
} <<< "$mp3_files"
