#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2025-02-27 20:04:28 +0700 (Thu, 27 Feb 2025)
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
Restores a file from the latest online Mac Timemachine backup where it exists

Prints the backup disks and then checks the variations of the backup paths mount point paths to find
the newest version
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<filename>"

help_usage "$@"

min_args 1 "$@"

filename="$1"
if ! [[ "$filename" =~ ^/ ]]; then
    filename="$PWD/$filename"
fi

timestamp "Backups;"
echo
tmutil destinationinfo
echo

timestamp "Determining backup mount point"
mountpoints="$(tmutil destinationinfo | awk -F " : " '/^Mount Point/{print $2}')"
timestamp "Backup Mount Points Online:

$mountpoints
"

#timestamp "Determining latest backup"
#latest_backup="$(tmutil latestbackup)"

#if ! [ -d "$latest_backup" ]; then
#    timestamp "Backup path returned by tmutil not found: $latest_backup"
#    timestamp "Trying alternative path"
#    latest_backup="$mountpoint/$(tmutil latestbackup | sed 's|.*/||')"
#    if ! [ -d "$latest_backup" ]; then
#        timestamp "Backup path returned by tmutil not found: $latest_backup"
#        timestamp "Trying previous instead of current backup"
#        latest_backup="${latest_backup%.backup}.previous"
#    fi
#    if ! [ -d "$latest_backup" ]; then
#        die "Latest backup alternative path not found; $latest_backup"
#    fi
#    timestamp "Latest Backup: $latest_backup"
#fi

# lists backups that are present on the current mount
#backups="$(tmutil listbackups | sed 's|.*/||; s|\.backup$||; s|\.previous$||' | tail -r)"
# shellcheck disable=SC2012
backups="$(
    while read -r mountpoint; do
        ls -t "$mountpoint" |
        sed '
            s|\.backup/*$||;
            s|\.previous/*$||;
            /plist/d;
        '
    done <<< "$mountpoints" |
    sort -r
)"
backupfile=""
for backup in $backups; do
    while read -r mountpoint; do
        for suffix in backup previous; do
            backupfile="$mountpoint/$backup.$suffix/Data/$filename"
            timestamp "Checking for file: $backupfile"
            if [ -f "$backupfile" ]; then
                echo
                timestamp "Found backup file: $backupfile"
                break 3
            fi
        done
    done <<< "$mountpoints"
done
if ! [ -f "$backupfile" ]; then
    die "ERROR: failed to find $filename in any backups"
fi

timestamp "Restoring $filename"
echo
tmutil restore "$backupfile" "$filename"
