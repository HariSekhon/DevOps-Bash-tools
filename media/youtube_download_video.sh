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

Even resumes downloads after network interruptions or a Control-C and re-run the command later

Installs yt-dlp (for downloading) and ffmpeg (for conversions) via OS package manager if not already installed

Automatically tries to upgrade the yt-dlp and ffmpeg packages first as sites like YouTube update their site
regularly breaking this and requiring a yt-dlp update - you should only install yt-dlp and ffmpeg using your OS
package manager for this to work, otherwise you'll be having to upgrade yt-dlp often yourself manually

If you run into a error determining a video format to download such as this:

    WARNING: [youtube] RVVDi1PHgw4: nsig extraction failed: Some formats may be missing

If you run into this error:

    ERROR: [youtube] ...: Sign in to confirm you’re not a bot.

Then set this in your shell first with the name of your browser:

    export COOKIES_FROM_BROWSER=chrome

You can specify the download format using args eg. --format, but you can also set this in environment variable used
by this script:

    export YT_DLP_FORMAT='best[height=720]'

Tip: set this in direnv to have smaller quicker downloads using less disk space by limiting to good enough 720p,
especially for videos you're just going to quickly watch one time with the mpvd alias to delete the file after one
watch, see this documentation:

    https://github.com/HariSekhon/Knowledge-Base/blob/main/direnv.md

    https://github.com/HariSekhon/Knowledge-Base/blob/main/mpv.md
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<video_url> [<filename>.mp4 <yt-dlp-args>]"

help_usage "$@"

min_args 1 "$@"
#max_args 2 "$@"

url="$1"
file_basename_without_ext="${2:-%(title)s}"
shift || :
shift || :

output_filename="$file_basename_without_ext.%(ext)s"

# default to trying get the best video and audio format we can
default_format="bestvideo[ext=mp4][vcodec^=avc1]+bestaudio/best[ext=mp4]"

# override the format with direnv in your ~/Downloads or ~/Downloads/YouTube dir
# dir if you want faster downloads at a good enough format:
#
#   eg. export YT_DLP_FORMAT='best[height=720]'
#
format="${YT_DLP_FORMAT:-$default_format}"

export HOMEBREW_NO_ENV_HINTS=1

# In case installed manually but not in package manager...
#
# Update: expect user to be using package manager so we can auto-upgrade yt-dlp which is needed often
#
#for cmd in yt-dlp ffmpeg; do
#    if ! type -P "$cmd" &>/dev/null; then
#        timestamp "$cmd not found in \$PATH, attempting to install..."
#        echo
#        "$srcdir/../packages/install_packages.sh" "$cmd"
#        echo
#    fi
#    check_bin "$cmd"
#done

"$srcdir/../packages/install_packages_if_absent.sh" yt-dlp ffmpeg

"$srcdir/../packages/upgrade_packages_if_outdated.sh" yt-dlp ffmpeg

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
# Increased retries to 50 because hotel wifi sucks around the world, which is why you want to download the videos
# for reliable offline play in the first place (or watching on the plane)
yt-dlp \
    --format "$format" \
    --merge-output-format mp4 \
    --continue \
    --no-overwrite \
    --retries 50 \
    --output "$output_filename" \
    ${DEBUG:+--verbose} \
    ${COOKIES_FROM_BROWSER:+--cookies-from-browser "$COOKIES_FROM_BROWSER"} \
    "$@" \
    "$url"

if [ "${2:-}" ]; then
    # quicker and should always be the arg and .mp4 due to the --format options above
    filename="$file_basename_without_ext.mp4"
else
    # if the filename isn't specified, we can infer it since no filename specified means no path specified so
    # we can infer it to be the most recent file with an mp4 extension in $PWD
    # shellcheck disable=SC2012
    # this doesn't work reliably, the timestamp of a newer downloaded video file can be older, resulting in opening
    # the wrong video
    #"$srcdir/vidopen.sh" "$(ls -t ./*.mp4 | head -n1)"
    timestamp "Determining download filename"
    # "$format" is only needed here for it to return the right file extension
    # in the "$output_filename" format eg. '.mp4' instead of '.webm'
    filename="$(
        yt-dlp --get-filename \
               --format "$format" \
               --merge-output-format mp4 \
               --output "$output_filename" \
               ${COOKIES_FROM_BROWSER:+--cookies-from-browser "$COOKIES_FROM_BROWSER"} \
               "$@" \
               "$url"
    )"
fi
if ! [ -f "$filename" ]; then
    die "Failed to find expected output file: $filename"
fi
timestamp "Touching file timestamp to make it easier to find when browsing"
touch -- "$filename"
#if is_mac; then
#    timestamp "Showing in Finder"
#    open -R "$filename"
#fi
if [ -z "${NO_VIDEO_OPEN:-}" ]; then
    timestamp "Opening video file: $filename"
    "$srcdir/vidopen.sh" "$filename"
fi
timestamp "Download Complete: $filename"
