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
Downloads all videos from an entire YouTube channel using yt-dlp

Installs yt-dlp (for downloading) and ffmpeg (for conversions) via OS package manager if not already installed
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<youtube_channel_url>"

help_usage "$@"

min_args 1 "$@"

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

#yt-dlp -f mp4 -c -w -o "%(upload_date)s - %(title)s.%(ext)s" -v "$1"

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
yt-dlp \
    --format "bestvideo[ext=mp4][vcodec^=avc1]+bestaudio[ext=m4a]/best[ext=mp4]" \
    --merge-output-format mp4 \
    --continue \
    --no-overwrite \
    --output "%(autonumber)s - %(title)s.%(ext)s" \
    ${DEBUG:+--verbose} \
    "$1"
