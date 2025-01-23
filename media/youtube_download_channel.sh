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

if ! type -P yt-dlp &>/dev/null; then
    timestamp "yt-dlp not found in \$PATH, attempting to install..."
    echo
    "$srcdir/../packages/install_packages.sh" yt-dlp
    echo
fi

# https://github.com/yt-dlp/yt-dlp#output-template

# -c --continue
# -w --no-overwrite
# -o --output format file name
# -v --verbose
#yt-dlp -f mp4 -c -w -o "%(upload_date)s - %(title)s.%(ext)s" -v "$1"
yt-dlp \
    --format mp4 \
    --continue \
    --no-overwrite \
    --output "%(autonumber)s - %(title)s.%(ext)s" \
    --verbose \
    "$1"
