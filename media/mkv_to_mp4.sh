#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-05-19 19:42:22 +0100 (Tue, 19 May 2020)
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

# shellcheck disable=SC2034,SC2154
usage_description="
Converts any MKV files given or found recursively under given paths or current directory to mp4 format using ffmpeg

Useful to be able to stream videos to devices like smart TVs that may otherwise not understand the codecs used in the original format

Names the generated files the same except with the '.mkv' extension replaced with '.mp4'

Skips files which already have a corresponding adjacent '.mp4' file present to be able to resume partial directory
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
    while read -r filepath; do
        mp4_filepath="${filepath%.mkv}.mp4"
        #if [ -n "${FORCE_OVERWRITE:-}" ] ||
        if ! [ -s "$mp4_filepath" ]; then
            # shellcheck disable=SC2016
            trap_cmd 'echo; echo "removing partially done file:"; rm -fv "$mp4_filepath"; untrap'
            timestamp "converting $filepath => $mp4_filepath"
            if [ -n "${QUICK:-}" ]; then
                time nice ffmpeg -i "$filepath" -vcodec copy -acodec copy -scodec mov_text -movflags +faststart "$mp4_filepath" < /dev/null  # don't let the ffmpeg command eat the incoming filenames
                # -sn disabled subtitle stream
                #time nice ffmpeg -i "$filepath" -vcodec copy -acodec copy -sn -movflags +faststart "$mp4_filepath" < /dev/null  # don't let the ffmpeg command eat the incoming filenames
            else
                # the default encoder doesn't work on TV for some stuff
                time nice ffmpeg -i "$filepath" "$mp4_filepath" < /dev/null  # don't let the ffmpeg command eat the incoming filenames

                # don't copy codec as is but transcode into something your TV can understand / pause / forward
                #time nice ffmpeg -i "$filepath" -c:v libx264 -movflags +faststart "$mp4_filepath" < /dev/null

                # none of this worked either
                #time nice ffmpeg -i "$filepath" \
                #    -vcodec mpeg4 \
                #    -acodec aac \
                #    -sn \
                #    -movflags +faststart \
                #    "$mp4_filepath" < /dev/null
                # -vcodec libxvid # really pixelated even at 1GB -> 1GB conversion
                # -vcodec mpeg4   # works but extremely pixelated
                #   -qscale:v 17    # even with this, and the files come out huge, bigger than MKV originals
                #-acodec mp3   # aac is native and better quality
                #
                # none of these work on my TV
                #-vcodec libx264
                #-vcodec mpeg2 # not found - must be too old and not compiled in
            fi
            echo >&2
        fi
    done < <(find "$basedir" -type f -iname '*.mkv')
done

echo >&2
timestamp "All conversions completed in $SECONDS secs"
untrap
