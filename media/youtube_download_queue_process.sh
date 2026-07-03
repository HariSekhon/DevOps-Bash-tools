#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2026-07-03 00:15:06 +0200 (Fri, 03 Jul 2026)
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

queue_basedir="$HOME/.yt-dlp-queue"

# shellcheck disable=SC2034,SC2154
usage_description="
Takes the next item from the download queue and calls youtube_download_video.sh on it
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args=""

help_usage "$@"

no_more_args "$@"

while true; do
    queue_item="$("$srcdir/../data/queue_process.sh" "$queue_basedir")"
    if is_blank "$queue_item"; then
        break
    fi
    url="$(cat "$queue_item")"
    if "$srcdir/youtube_download_video.sh" "$url"; then
        timestamp "Completed - removing queued item: $queue_item"
        rm -f "$queue_item"
    else
        "$srcdir/../data/queue_requeue.sh" "$queue_item"
    fi
done
