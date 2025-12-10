#!/usr/bin/env bash
#
#   Author: Hari Sekhon
#   Date: 2012-07-10 15:36:54 +0100 (Tue, 10 Jul 2012)
#  $LastChangedBy$
#  $LastChangedDate$
#  $Revision$
#  $URL$
#  $Id$
#
#  vim:ts=4:sw=4:et

set -e
set -u

die(){
    echo "$@"
    exit 1
}

usage(){
    die "usage: $0 -p /mount/point -s size_MB"
}

mount_point=""
size=""
until [ $# -lt 1 ]; do
    case $1 in
        -p) mount_point=$2
            shift
            ;;
        -s) size=$2
            shift
            ;;
         *) usage
            ;;
    esac
    shift
done

[ -n "$mount_point" ] || usage
[ -n "$size" ] || usage

mkdir -p "$mount_point" || die "The mount point didn't available."

sector=$(expr $size \* 1024 \* 1024 / 512)
device_name=$(hdid -nomount "ram://${sector}" | awk '{print $1}')
[[ "$device_name" =~ /dev/disk* ]] || die "Failed to create/get ramdisk "
[[ "$device_name" =~ /dev/disk[123] ]] && die "ERROR: returned $device_name, one of first 3 disks, aborting for safety"
newfs_hfs -U hari "$device_name" || die "failed to create hfs filesystem"
mount -t hfs "$device_name" "$mount_point" || die "Failed to mount $device_name at $mount_point"
echo "Mounted $device_name at $mount_point"
# To get rid of this ramdisk
# umount "$mount_point"
# hdiutil detach -quiet "$device_name"
