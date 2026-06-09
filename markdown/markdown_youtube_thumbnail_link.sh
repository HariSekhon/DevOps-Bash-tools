#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2026-06-10 00:01:43 +0200 (Wed, 10 Jun 2026)
#
#  https///github.com/HariSekhon/DevOps-Bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn
#  and optionally send me feedback
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
Creates a markdown thumbnail link for the given youtube video URL
and copies it to the clipboard for quick pasting into your markdown

Requires yt-dlp to be installed to determine the video title for the markdown title
(attempts to install it if not found in \$PATH)
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<https://www.youtube.com/watch?v=...>"

help_usage "$@"

min_args 1 "$@"

youtube_url="$1"

if ! [[ "$youtube_url" =~ ^https://www\.youtube\.com/watch\?v=.+ ]]; then
    usage "Invalid YouTube URL given: $youtube_url"
fi

youtube_url="${youtube_url%%&*}"

video_id="${youtube_url##*v=}"

if ! [[ "$video_id" =~ ^[[:alnum:]-]+$ ]]; then
    die "Invalid video ID '$video_id' extracted from TouTube URL: $youtube_url"
fi

if ! type -P yt-dlp &>/dev/null; then
    "$srcdir/../packages/install_packages.sh" yt-dlp
fi

timestamp "Getting YouTube video title"
#video_title="$(yt-dlp --print title "$youtube_url")"
video_title="$(
    yt-dlp --get-title "$youtube_url" |
    # strip chars that might interfere with the markdown title
    sed 's/[\[\]]/ /g'
)"

markdown_link="[![$video_title](https://img.youtube.com/vi/$video_id/0.jpg)](https://www.youtube.com/watch?v=$video_id)"

timestamp "Markdown link with thumbnail:"
echo >&2
echo "$markdown_link" |
tee >("$srcdir/../bin/copy_to_clipboard.sh")
