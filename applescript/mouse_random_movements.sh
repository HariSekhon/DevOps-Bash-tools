#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2024-12-06 08:09:48 +0700 (Fri, 06 Dec 2024)
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
. "$srcdir/../lib/utils.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Randomly moves the mouse around the screen

Useful to prevent a screensaver kicking in on a Remote Desktop connection which has Active Directory Group Policies
applied that doesn't let you disable the screensaver

Sleeps for 10 seconds between mouse movements
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<sleep_seconds> <num_movements>]"

help_usage "$@"

max_args 2 "$@"

sleep_secs="${1:-10}"

num="${2:--1}"

if ! is_float "$sleep_secs"; then
    usage "invalid non-float argument given for sleep seconds: $sleep_secs"
fi

if [ "$sleep_secs" -lt 1 ]; then
    usage "Sleep seconds cannot be less than 1"
fi

if ! [[ "$num" =~ ^-?[[:digit:]]+$ ]]; then
    usage "invalid non-integer num movements given for first argument: $num"
fi

if ! type -P cliclick &>/dev/null; then
    brew install cliclick
fi

timestamp "Starting random mouse movements"
echo

screen_width="$(system_profiler SPDisplaysDataType | grep Resolution | awk '{print $2}')"
screen_height="$(system_profiler SPDisplaysDataType | grep Resolution | awk '{print $4}')"

for ((i=1; ; i++)); do
    # if given num is negative, will run for infinity until Control-C'd
    if [ "$num" -ge 0 ] &&
       [ "$i" -gt "$num" ]; then
        break
    fi
    x="$((RANDOM % screen_width))"
    y="$((RANDOM % screen_height))"
    timestamp "Mouse movement $i/$num at $x , $y"
    cliclick "m:$x,$y"
    sleep "$sleep_secs"
done
