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

# shellcheck disable=SC2034,SC2154
usage_description="
Requeues the given item for reprocessing by moving it from processing/ back to pending/ dir
and moves it to the back of the queue so if it's a faulty item it doesn't block a calling
script's processing loop

Expects a full file path to a queue_basedir/processing/<item> as emitted by the adjacent script queue_add.sh

Infers the queue_basedir from the full queue item path
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<queue_item>"

help_usage "$@"

num_args 1 "$@"

queue_item="$1"

if ! [[ "$queue_item" =~ /processing/ ]]; then
    die "Invalid queue item path given, must be a path to a queue_basedir/processing/item"
fi

if ! [ -f "$queue_item" ]; then
    die "Error: queue item not found: $queue_item"
fi

pending_dir="${queue_item%%/processing/*}/pending"

mkdir -pv "$pending_dir"

requeued_item="$pending_dir/$(date '+%F_%H%M%S')-$$-$RANDOM"

 timestamp "Requeuing item $queue_item to $requeued_item"
mv "$queue_item" "$requeued_item"
