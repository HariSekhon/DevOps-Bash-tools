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
    echo "
Performs N mouse clicks at the current mouse coordinates location, 1 second apart to automate tedious UI actions

Starts clicking after 5 seconds to give time to alt-tab back to your UI application and position the cursor

${0##*/} <num>"
    exit 3
}

if [ $# != 1 ]; then
    usage
fi

if ! [[ "$1" =~ ^[[:digit:]]+$ ]]; then
    usage
fi

num="$1"

sleep 5

# shellcheck disable=SC2086
for i in $(seq "$num"); do
    timestamp "click $i"
    MouseTools -leftClick
    sleep 1
done
