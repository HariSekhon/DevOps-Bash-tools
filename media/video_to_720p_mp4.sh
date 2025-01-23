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
Converts one or more video files to 720p mp4 format using ffmpeg

Useful to make good trade-off of quality vs size for social media sharing

Names the generated files the same except with the file extension replaced with '.720p.mp4'

Skips files which already have a corresponding adjacent '.720.mp4' file for safety

Removes partially complete files for consistency using bash trapping

Installs ffmpeg using OS package manager if not already installed
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<video_files>"

help_usage "$@"

min_args 1 "$@"

if ! type -P ffmpeg &>/dev/null; then
    timestamp "ffmpeg not found in \$PATH, attempting to install..."
    echo
    "$srcdir/../packages/install_packages.sh" ffmpeg
    echo
fi

check_bin ffmpeg

SECONDS=0

time \
for filepath in "$@"; do
    mp4_filepath="${filepath%.*}.720p.mp4"
    if [ -s "$mp4_filepath" ]; then
        timestamp "File already exists, skipping: $mp4_filepath"
    else
        # shellcheck disable=SC2016
        trap_cmd 'echo; echo "removing partially done file:"; rm -fv "$mp4_filepath"; untrap'
        timestamp "converting $filepath => $mp4_filepath"
        time nice ffmpeg -i "$filepath" -vf "scale=-1:720" -c:v libx264 -crf 23 -preset medium -c:a copy -movflags +faststart "$mp4_filepath"
        echo >&2
    fi
done

echo >&2
timestamp "All conversions completed in $SECONDS secs"
untrap
