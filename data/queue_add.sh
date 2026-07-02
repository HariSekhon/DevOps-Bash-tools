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
Creates an atomic queue file at the given location with the given data

If no queue basedir is provided, defaults to:

$queue_basedir

If no data is given, reads the data from stdin
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<queue_basedir> <data>]"

help_usage "$@"

max_args 2 "$@"

if [ $# -eq 2 ]; then
    queue_basedir="$1"
    data="$2"
else
    warn "Using default queue basedir: $queue_basedir"
    if [ $# -eq 1 ]; then
        data="$1"
    else
        warn "Reading data from stdin"
        data="$(cat)"
    fi
fi

mkdir -p "$queue_basedir/"{pending,tmp}

tmp="$(mktemp "$queue_basedir/tmp/tmp.XXXXXX")"

echo "$data" > "$tmp"

mv "$tmp" "$queue_basedir/pending/$(date '+%F_%H%M%S')-$$-$RANDOM"
timestamp "Added to queue at $queue_basedir"
