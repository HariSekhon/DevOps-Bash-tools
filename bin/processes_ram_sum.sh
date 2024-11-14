#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#  args: chrome
#
#  Author: Hari Sekhon
#  Date: 2024-11-14 18:28:20 +0400 (Thu, 14 Nov 2024)
#
#  https///github.com/HariSekhon/DevOps-Bash-tools
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
. "$srcdir/lib/utils.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Sums the RAM usage of all processes matching a given regex in GB to one decimal place

Writen to find out how much RAM Google Chrome and all its many helper processes were actually consuming
since my fancy M3 Max was using 100/128GB RAM and the top few processes only accounted for roughly ~10GB of that

It turned out Chrome was taking around 52GB for all the many tabs I had open
while IntelliJ and its plugins were taking 17.8GB rather than the 5.8GB reported
for the main IntellJ process in Activity Monitor, which is misleading,
while jcef processes were taking another 5.6GB

Regex matches the entire process line return by 'ps aux' so this catches processes running out of installation
directories that may have different names

This means that

    ${0##*/} google

will sum both Google Chrome and Google Drive processes which is why

    ${0##*/} google

results in slightly higher GB sum than

    ${0##*/} chrome


Tested on Mac, but should work on Linux too
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<process_regex>"

help_usage "$@"

min_args 1 "$@"

process_regex="$1"

# cannot use pgrep because it doesn't output RSS memory used and would necessitate iterating over pids with something like
#
#   ps -o rss= -p "$pid"
#
# which would be lots of needless inefficient process forks
#
# shellcheck disable=SC2009
memory_kb="$(ps aux | grep -Ei "$process_regex" | grep -v grep | awk '{sum += $6} END {print sum}')"

# convert KB to GB and round to one decimal place
memory_gb="$(awk "BEGIN {printf \"%.1f\", $memory_kb / 1024 / 1024}")"

echo "Total memory used by all processes matching the '$process_regex' regex: $memory_gb GB"
