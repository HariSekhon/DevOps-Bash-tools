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

# shellcheck disable=SC2034,SC2154
usage_description="
Returns the next queued item path after atomically moving it to 'processing/' dir

Th calling script can then read the queue item's data to begin processing

The calling script is responsible for removing the returned item path if processing completed successfully,
or else calling queue_requeue.sh against it to move it back to the pending/ queue dir

Otherwise a future queue_recover.sh process will detect the time as stale and move it back to the pending/ queue dir,
which will result in duplicate processing if the calling script forgets to 'ack' it as completed by removing it
from the processing/ queue dir

If processing will take longer than the queue_recover.sh time then the client script is also responsible for 'touch'ing
the processing item file at a frequency more frequent than the queue_recover.sh stale threshold

If no queue basedir is provided, defaults to:

$queue_basedir
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<queue_basedir>]"

help_usage "$@"

max_args 1 "$@"

if [ $# -eq 1 ]; then
    queue_basedir="$1"
else
    warn "Using default queue basedir: $queue_basedir"
fi

next_queue_item="$(find "$queue_basedir/pending/" -maxdepth 1 -type f | head -n 1)"

if is_blank "$next_queue_item"; then
    die "No more queued items found"
fi

processing_dir="$queue_basedir/processing"

mkdir -p "$processing_dir"

next_process_item="$processing_dir/${next_queue_item##*/}"

if mv "$next_queue_item" "$next_process_item"; then
    echo "$next_process_item"
fi
