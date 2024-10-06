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
Add / Modify track name metadata to match MP3 filenames for all MP3s in the given directories to improve display appearance when playing

The track name metadata is taken to be the basename of the MP3 file without the extension

$mp3_usage_behaviour_msg
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<dir1> <dir2> ...]"

help_usage "$@"

check_bin id3v2

shift || :

# used to pipe file list inline which is more comp sci 101 correct but that could create a race condition on second
# evaluation of file list changing after confirmation prompt, and RAM is cheap, so better to use a static list of files
# stored in ram and operate on that since it'll never be that huge anyway

mp3_files="$(get_mp3_files "${@:-$PWD}")"

echo "List of MP3 files => track names to be set:"

echo

shopt -s nocasematch

mp3_regex='([^/]+).mp3$'

get_track_name(){
    local mp3="$1"
    local artist
    #track_name="$mp3"
    #track_name="${track_name##*/}"
    #track_name="${track_name%.mp3}"
    #track_name="${track_name%.MP3}"
    # case insensitive matching without subshelling
    if [[ "$mp3" =~ $mp3_regex ]]; then
        track_name="${BASH_REMATCH[1]}"
    else
        die "failed to regex match filename '$mp3' to generate track name"
    fi
    artist="$(id3v2 -l "$mp3" |
        grep '[[:space:]]Artist:[[:space:]]' | sed 's/.*[[:space:]]Artist:[[:space:]]*//; s/[[:space:]]*$//'
    )"
    track_name="${track_name#$artist}"
    track_name="${track_name#[[:space:]]*-[[:space:]]*}"
    echo "$track_name"
}

while read -r mp3; do
    track_name="$(get_track_name "$mp3")"
    echo "'$mp3' => '$track_name'"
done <<< "$mp3_files"

echo

read -r -p "Are you happy to set the track name metadata on all of the above mp3 files? (y/N) " answer

check_yes "$answer"

echo

while read -r mp3; do
    track_name="$(get_track_name "$mp3")"
    echo "setting track name metadata on '$mp3' to '$track_name'"
    id3v2 --song "$track_name" "$mp3"
done <<< "$mp3_files"
