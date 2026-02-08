#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2025-01-26 08:01:28 +0700 (Sun, 26 Jan 2025)
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
Opens the given video file using whatever available tool is found on Linux or Mac

On Mac, the following environment variable can alter behaviour:

    DEFAULT_VIDEO_PLAYER - the name of the video player to use eg. 'QuickTime Player'
    BACKGROUND_VIDEO     - if set to any value, opens in the background (does not automatically play),
                           used in scripts like those below to prevent long-running downloads from popping into the
                           foreground interrupting your workflow and having to Cmd-Tab back every time
    PLAY_VIDEO           - if set to any value, starts playing the video (currently only tested on 'QuickTime Player')

Used by the following scripts:

    youtube_download_video.sh
    twitter_download_video.sh
    x_download_video.sh
    video_to_720p_mp4
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<video_file>"

help_usage "$@"

num_args 1 "$@"

video="$1"

# Will be tried in this order
linux_commands=(
    mpv
    mplayer
    vlc
    ffplay
    totem
    xine
)
    #smplayer  # requires args unlike the others: smplayer -send-action play_current_file

if is_mac; then
    opts=()
    # if the video player has a binary in \$PATH then use it, otherwise assume it's an /Application/NAME.app
    if type -P "${DEFAULT_VIDEO_PLAYER-}" &>/dev/null; then
        if [ "$DEFAULT_VIDEO_PLAYER" = mpv ]; then
            if [ -z "${PLAY_VIDEO:-}" ]; then
                opts+=("--pause=yes")
            fi
        fi
        "$DEFAULT_VIDEO_PLAYER" "${opts[@]}" -- "$video" &
    else
        if [ -n "${BACKGROUND_VIDEO:-}" ]; then
            opts+=(-g)
        fi
        if [ -n "${DEFAULT_VIDEO_PLAYER:-}" ]; then
            opts+=(-a "$DEFAULT_VIDEO_PLAYER")
        fi
        open "${opts[@]}" "$video"
        if [ -n "${PLAY_VIDEO:-}" ]; then
            osascript -e "tell application \"${DEFAULT_VIDEO_PLAYER:-QuickTime Player}\" to play document 1"
        fi
    fi
else  # assume Linux
    found=0
    for linux_command in "${linux_commands[@]}"; do
        if type -P "$linux_command" &>/dev/null; then
            found=1
            "$linux_command" -- "$video" &
            break
        fi
    done
    if [ "$found" != 1 ]; then
        die "ERROR: none of the following Linux commands to open video were found: ${linux_commands[*]}"
    fi
fi
