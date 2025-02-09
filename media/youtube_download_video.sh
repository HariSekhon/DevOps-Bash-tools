#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2023-09-17 01:42:27 +0100 (Sun, 17 Sep 2023)
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
Downloads a YouTube, Facebook or Twitter / X video to mp4 with maximum quality and compatibility using yt-dlp

Opens the video automatically for you to check the download

Installs yt-dlp (for downloading) and ffmpeg (for conversions) via OS package manager if not already installed
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<video_url> [<filename>.mp4]"

help_usage "$@"

min_args 1 "$@"
max_args 2 "$@"

url="$1"
filename="${2:-%(title)s}.%(ext)s"

#"$srcdir/../packages/install_packages_if_absent.sh" yt-dlp ffmpeg

# in case installed manually but not in package manager
for cmd in yt-dlp ffmpeg; do
    if ! type -P "$cmd" &>/dev/null; then
        timestamp "$cmd not found in \$PATH, attempting to install..."
        echo
        "$srcdir/../packages/install_packages.sh" "$cmd"
        echo
    fi
    check_bin "$cmd"
done

# https://github.com/yt-dlp/yt-dlp#output-template

# -c --continue
# -w --no-overwrite
# -o --output format file name
# -v --verbose (debug output)
#
# --format mp4 \
#
# --format best - results in poor quality video in testing due to video only and audio only combinations
#
# --format "bestvideo+bestaudio/best" - unfortunately this results in a file that macOS QuickTime can't open natively
#                                       (although VLC can but then VLC was always the best)
#
#       bestvideo+bestaudio: downloads the best video and audio streams separately and merges them (requires ffmpeg or avconv)
#       /best: falls back to the best single file if the video+audio combination isn't available
#
# for maximum compatibility specify compatible formats
#
#    --output "%(title)s.%(ext)s" \
#
yt-dlp \
    --format "bestvideo[ext=mp4][vcodec^=avc1]+bestaudio[ext=m4a]/best[ext=mp4]" \
    --merge-output-format mp4 \
    --continue \
    --no-overwrite \
    --output "$filename" \
    ${DEBUG:+--verbose} \
    "$url"

if [ "${2:-}" ]; then
    filename="$2.mp4"
else
    # if the filename isn't specified, we can infer it since no filename specified means no path specified so
    # we can infer it to be the most recent file with an mp4 extension in $PWD
    # shellcheck disable=SC2012
    # this doesn't work reliably, the timestamp of a newer downloaded video file can be older, resulting in opening
    # the wrong video
    #"$srcdir/vidopen.sh" "$(ls -t ./*.mp4 | head -n1)"
    timestamp "Determining download filename"
    filename="$(yt-dlp --get-filename --output "%(title)s.mp4" "$url")"
fi
timestamp "Touching file timestamp to make it easier to find when browsing"
touch "$filename"
timestamp "Opening video file: $filename"
#if is_mac; then
#    timestamp "Showing in Finder"
#    open -R "$filename"
#fi
"$srcdir/vidopen.sh" "$filename"
