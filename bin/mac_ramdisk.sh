#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2012-07-10 15:36:54 +0100 (Tue, 10 Jul 2012)
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
Creates and mounts a macOS ramdisk of the given size in MB

To remove the ramdisk, just run:

    diskutil eject /Volumes/Ramdisk
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<MB_size>]"

help_usage "$@"

num_args 1 "$@"

MB="$1"

if ! is_int "$MB"; then
    die "Invalid argument given, MB must be an integer"
fi

blocks="$(("$MB" * 1024 * 1024 / 512))"

list_ramdisks() {
    diskutil list | \
    awk '
        /^\// {disk=$1}
        /RAM Disk/ {print disk}
    ' | \
    while read -r d; do
        mp=$(mount | awk -v d="$d" '$1==d {print $3}')
        printf "%s %s\n" "$d" "$mp"
    done
}

existing="$(list_ramdisks)"

if [ -n "$existing" ]; then
    timestamp "Existing RAM disks found:"
    echo "$existing"
    die "Refusing to create a new RAM disk; please reuse or eject the existing one(s) to avoid leaking ramdisks from repeated runs"
fi

timestamp "Creating ramdisk of size '$MB' MB => '$blocks' blocks"
disk="$(hdiutil attach -nomount ram://$blocks)"
timestamp "Created: $disk"
echo
diskutil list
echo
timestamp "SAFETY: double check the disk and then run format to mount the Ramdisk with HFS+: $disk"
echo
echo diskutil erasevolume HFS+ "Ramdisk" "$disk"
