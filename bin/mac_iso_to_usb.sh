#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2024-03-06 02:09:22 +0000 (Wed, 06 Mar 2024)
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
Converts a given ISO file to a USB bootable image and burns it onto a given or detected inserted USB drive

Prompts to insert a USB drive, diffs which device this turns up as, then prompts for confirmation and continues write to it

The Etcher app is also recommended for a GUI solution:

    https://etcher.balena.io/

UNetbootin is also a classic choice with upstream distribution integration as well as downloaded ISO support
If it doesn't detect your USB drive, use Disk Utility to format it as MS-DOS (FAT32) to get it to detect it

    https://unetbootin.github.io/

Tested on macOS 14 Sonoma
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<iso_file> [<usb_device>]"

help_usage "$@"

if ! is_mac; then
    die "Only macOS is supported"
fi

min_args 1 "$@"
max_args 2 "$@"

iso="$1"
usb_drive="${2:-}"

if ! [[ "$iso" =~ \.iso$ ]]; then
    usage "specified ISO file does not end in .iso - aborting for safety"
fi

if [ -n "$usb_drive" ] && ! [[ "$usb_drive" =~ ^/dev/ ]]; then
    usage "specified device '$usb_drive' does not start with /dev/... aborting for safety"
fi

img="${iso%.iso}.img"

trap_cmd "rm -f '$img'"

if [ -f "$img" ]; then
    timestamp "IMG file '$img' already exists, skipping for now"
else
    timestamp "Converting ISO file '$iso' to '$img'"
    hdiutil convert -format UDRW -o "$img" "$iso"
    mv "$img.dmg" "$img"
    untrap
fi

echo
timestamp 'Disks:'
echo
disks_before="$(diskutil list | tee /dev/stderr)"
echo

if is_blank "$usb_drive"; then
    read -r -p 'Enter your USB disk and then press Enter'
    # sleep a couple seconds to give the Mac a chance to detect the inserted USB disk
    sleep 4
    echo

    timestamp 'Disks:'
    echo
    disks_after="$(diskutil list | tee /dev/stderr)"
    echo

    echo 'New USB disks detected:'
    echo
    usb_drive="$(diff -w <(echo "$disks_before") <(echo "$disks_after") | tee /dev/stderr | grep -Eo '/dev/disk[[:digit:]]+' | head -n 1 || :)"
    echo
    if [ -z "$usb_drive" ]; then
        die 'Failed to detect USB disk'
    fi
    echo "Determined USB drive to be: '$usb_drive'"
    echo
else
    echo "You have selected disk '$usb_drive' from the above list"
    echo
fi

if ! [[ "$usb_drive" =~ /dev/disk[[:digit:]]+$ ]]; then
    die "USB drive determined to be '$usb_drive' but this does not match expected regex of /dev/diskN - aborting for safety"
fi

read -r -p 'Does this look correct? Continue? (y/N) ' answer

check_yes "$answer"

echo
timestamp 'Unmounting USB drive'
echo
diskutil unmountDisk "$usb_drive" || :
echo

raw_usb_drive="${usb_drive/\/disk//rdisk}"

timestamp 'Writing to USB drive'
echo
sudo dd if="$img" of="$raw_usb_drive" bs=1m
echo

timestamp 'Finished writing, ejecting'
echo
diskutil eject "$usb_drive"
echo
timestamp 'Done'
