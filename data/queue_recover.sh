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

queue_basedir="$HOME/.queue"
stale_minutes_threshold="120"

# shellcheck disable=SC2034,SC2154
usage_description="
Scans for stale queue processing items more than N minutes old and requeues them for reprocessing
using adjacent script queue_requeue.sh (for cases where a script reader has died and another script will re-run on it)

If no queue basedir is provided, defaults to:

$queue_basedir

Stale minutes threshold if not specified: $stale_minutes_threshold
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<queue_basedir> <stale_minutes_threshold>]"

help_usage "$@"

max_args 2 "$@"

if [ $# -eq 2 ]; then
    queue_basedir="$1"
    stale_minutes_threshold="$2"
else
    warn "Using default stale minutes threshold: $stale_minutes_threshold"
    if [ $# -eq 1 ]; then
        queue_basedir="$1"
    else
        warn "Using default queue basedir: $queue_basedir"
    fi
fi

if ! is_int "$stale_minutes_threshold"; then
    die "Invalid stale minutes threshold given, must be an integer: $stale_minutes_threshold"
fi

pending_dir="$queue_basedir/pending"
processing_dir="$queue_basedir/processing"

mkdir -p "$pending_dir" "$processing_dir"

stale_items="$(find "$processing_dir" -maxdepth 1 -type f -ctime "+${stale_minutes_threshold}m")"

if is_blank "$stale_items"; then
    timestamp "No stale queue items found"
    exit 0
fi

while read -r line; do
    if is_blank "$line"; then
        continue
    fi
    "$srcdir/queue_requeue.sh" "$line"
done <<< "$stale_items"
