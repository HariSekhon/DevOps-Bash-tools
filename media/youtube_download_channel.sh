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
Uses yt-dlp to download an entire YouTube channel of videos
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<youtube_channel_url>"

help_usage "$@"

min_args 1 "$@"

# https://github.com/yt-dlp/yt-dlp#output-template

#yt-dlp -f mp4 -cw -o "%(upload_date)s - %(title)s.%(ext)s" -v "$1"
yt-dlp -f mp4 -cw -o "%(autonumber)s - %(title)s.%(ext)s" -v "$1"
