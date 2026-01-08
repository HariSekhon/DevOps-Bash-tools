#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2026-01-08 08:32:28 -0500 (Thu, 08 Jan 2026)
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
Deletes local macOS snapshots to free up disk space

When there is a substantial discrepancy between what the 'df -h' command and the Finder UI shows,
this is often the cause

Path defaults to /

Requires being run as root or having sudo privileges
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<path>]"

help_usage "$@"

max_args 1 "$@"

export path="${1:-/}"

if ! [ -d "$path" ]; then
    die "ERROR: invalid directory given: $path"
fi

show_disk_space(){
    #timestamp "Disk Space Finder Sees:
    #"
    #
    #diskutil info "$path" | grep 'Free Space'
    #echo

    timestamp "Disk Space:"
    echo
    df -h "$path"
    echo
}

show_disk_space

snapshots="$(
    tmutil listlocalsnapshots "$path" |
    tail -n +2 |
    awk -F. '{print $4}' |
    sed '/^[[:space:]]*$/d'
)"

# because wc -l returns 1 on an empty line due to a \n newline
num_snapshots="$(grep -c . <<< "$snapshots" || :)"

timestamp "Snapshots to Delete: $num_snapshots"
echo

if [ "$num_snapshots" -lt 1 ]; then
    timestamp "No snapshots to delete, exiting."
    exit 0
fi

timestamp "Deleting Time Machine Snapshots"
echo

while read -r snapshot_timestamp; do
    timestamp "Deleting local snapshot: $snapshot_timestamp"
    sudo tmutil deletelocalsnapshots "$snapshot_timestamp"
    echo
done <<< "$snapshots"

show_disk_space
