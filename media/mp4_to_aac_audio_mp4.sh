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
Converts one or more mp4 files given or found recursively under given paths or current directory to use aac format audio using ffmpeg

Useful to quickly convert mp4 files with mp3 audio that don't work with QuickTime on macOS due to a limitation

Alternatively you can just use a stronger video player like VLC

Names the generated files the same except with the '.mp4' extension prefixed with '.aac.mp4'

Skips files which already have a corresponding adjacent '.aac.mp4' file present to be able to resume partial directory
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
        aac_filepath="${filepath%.mp4}.aac.mp4"
        if [ -s "$aac_filepath" ]; then
            timestamp "File already exists, skipping: $aac_filepath"
        else
            # shellcheck disable=SC2016
            trap_cmd 'echo; echo "removing partially done file:"; rm -fv "$aac_filepath"; untrap'
            timestamp "converting $filepath => $aac_filepath"
            time nice ffmpeg -i "$filepath" -c:v copy -c:a aac -b:a 192k -- "$aac_filepath" < /dev/null
            echo
        fi
    done < <(find "$basedir" -type f -iname '*.mp4' | grep -v '\.aac.mp4$' || :)
done

echo
echo "All conversions completed in $SECONDS secs"
untrap
