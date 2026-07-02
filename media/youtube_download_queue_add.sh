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
Add YouTube or other supported social media URLs for the related adjacent scripts to a durable local queue
for parallel recoverable download processing, thereby avoiding throttling errors from too many parallel
instant downloads

If no video URL is given, assumes reading one URL per line from stdin until there is no more stdin
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<video_url>]"

help_usage "$@"

max_args 1 "$@"

if [ $# -eq 1 ]; then
    "$srcdir/../data/queue_add.sh" "$queue_basedir" "$1"
else
    warn "reading URLs from stdin"
    while read -r line; do
        if is_blank "$line"; then
            continue
        fi
        "$srcdir/../data/queue_add.sh" "$queue_basedir" "$line"
    done
fi
