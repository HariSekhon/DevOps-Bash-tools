#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2026-09-18 09:01:13 +0800 (Fri, 18 Sep 2026)
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

# shellcheck disable=SC2034,SC2154
usage_description="
Converts one or more mp4 files given or found recursively under given paths or current directory to mov format using ffmpeg

Useful to quickly repackage mp4 files with mp3 audio that don't work with QuickTime on macOS due to a limitation, but can
then be played on QuickTime in mov format instead, and video edited using QuickTime

Alternatively if only playing then just play the existing mp4 file with a stronger video player like VLC

Names the generated files the same except with the '.mp4' extension replaced with '.mov'

Skips files which already have a corresponding adjacent '.mov' file present to be able to resume partial directory
conversions, and also removes partially complete files for consistency using bash trapping
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<files_or_directories>]"

help_usage "$@"

#min_args 1 "$@"

check_bin ffmpeg ||
"$srcdir/../packages/install_packages.sh" ffmpeg

SECONDS=0

time \
for basedir in "${@:-.}"; do
    if ! [[ "$basedir" =~ ^\.*/ ]]; then
        basedir="./$basedir"
    fi
    while read -r filepath; do
        mov_filepath="${filepath%.mp4}.mov"
        if [ -s "$mov_filepath" ]; then
            timestamp "File already exists, skipping: $mov_filepath"
        else
            # shellcheck disable=SC2016
            trap_cmd 'echo; echo "removing partially done file:"; rm -fv "$mov_filepath"; untrap'
            timestamp "converting $filepath => $mov_filepath"
            #time nice ffmpeg -i "$filepath" -- "$mp4_filepath" < /dev/null  # don't let the ffmpeg command eat the incoming filenames
            #time nice ffmpeg -i "$filepath" -vcodec copy -acodec copy -scodec mov_text -movflags +faststart -- "$mov_filepath" < /dev/null
            time nice ffmpeg -i "$filepath" -c copy -- "$mov_filepath" < /dev/null
            echo
        fi
    done < <(find "$basedir" -type f -iname '*.mp4')
done

echo
echo "All conversions completed in $SECONDS secs"
untrap
