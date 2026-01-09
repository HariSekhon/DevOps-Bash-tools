#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2026-01-09 02:25:20 -0500 (Fri, 09 Jan 2026)
#
#  https///github.com/HariSekhon/DevOps-Bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn
#  and optionally send me feedback to help steer this or other code I publish
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
Find large files in the currently in-progress Time Machine backup to find out what is taking so long
and racking up so many more GB of changes than you expect

Needs to be run during a Time Machine backup to be able to find the current '<date>-inprogress' directory

This helps discover large but unnecessary files that you might want to exclude using the adjacent script:

    mac_backup_exclude_paths.sh
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args=""

help_usage "$@"

no_more_args "$@"

mac_only

today="$(date '+%F')"
# this date command is specific to mac's BSD version of the date command
yesterday="$(command date -v -1d '+%F')"

shopt -s nullglob

matches=(/Volumes/*/"$today"-*.inprogress)

if [ "${#matches[@]}" -eq 0 ]; then
    timestamp "No currently dated inprogress dir found"
    timestamp "Attempting to find one dated yesterday in case the currently in-progress backup started before midnight"
    matches=(/Volumes/*/"$yesterday"-*.inprogress)
    if [ "${#matches[@]}" -eq 0 ]; then
        echo >&2
        die "ERROR: No currently in-progress Time Machine backup directories found for today or yesterday - this must be run during an active Time Machine backup"
    fi
fi

timestamp "Found in-progress dir(s): ${matches[*]}"
echo >&2

sudo du -max "${matches[@]}" |
sort -k1n |
tail -n 1000
