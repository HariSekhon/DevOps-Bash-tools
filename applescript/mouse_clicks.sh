#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-06-14 17:16:31 +0100 (Sun, 14 Jun 2020)
#
#  https://github.com/harisekhon/bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/harisekhon
#

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck disable=SC1090
. "$srcdir/../lib/utils.sh"

usage(){
    if [ -n "$*" ]; then
        echo "usage error: $*" >&2
        echo >&2
    fi
    echo "
Automates Mouse Clicks to automate tedious UI actions

Performs N mouse clicks at the sequence of X,Y coordinates given or the current mouse location if no coordinates

Sleeps for \$SLEEP_SECS (default: 1) between clicks to allow UIs to update and perform the next click

Starts clicking after \$START_DELAYS seconds (default: 5) to give time to alt-tab back to your UI application and position the cursor

${0##*/} <num> [<coordinates> <coordinates> <coordinates> ...]"
    exit 3
}

if [ $# -lt 1 ]; then
    usage
fi

num="$1"
start_delay="${START_DELAY:-5}"
sleep_secs="${SLEEP_SECS:-1}"

if ! [[ "$num" =~ ^[[:digit:]]+$ ]]; then
    usage "invalid non-integer '$num' given for first argument"
fi

if ! [[ "$sleep_secs" =~ ^[[:digit:]]+(\.[[:digit:]]+)?$ ]]; then
    usage "invalid non-float '$SLEEP_SECS' found in environment for \$SLEEP_SECS"
fi

shift || :

read -r -a coordinates <<< "$@"

if [ -n "${coordinates:-}" ]; then
    for coordinate in "${coordinates[@]}"; do
        if ! [[ "$coordinate" =~ ^[[:digit:]]+,[[:digit:]]+$ ]]; then
            usage "invalid coordinate '$coordinate' given - must be in form x,y"
        fi
    done
fi

timestamp "waiting for $start_delay secs before starting"
sleep "$start_delay"
timestamp "starting"
echo

for i in $(seq "$num"); do
    if [ -n "${coordinates:-}" ]; then
        for coordinate in "${coordinates[@]}"; do
            x="${coordinate%,*}"
            y="${coordinate#*,}"
            timestamp "mouse click $i at $x , $y"
            MouseTools -leftClick -x "$x" -y "$y"
            sleep "$sleep_secs"
        done
    else
        timestamp "mouse click $i at current mouse location"
        MouseTools -leftClick
        sleep "$sleep_secs"
    fi
done
