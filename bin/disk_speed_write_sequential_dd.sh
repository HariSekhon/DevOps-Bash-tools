#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2025-11-26 21:21:30 -0600 (Wed, 26 Nov 2025)
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
Runs a sequential write test to a file in the given or current directory in order to test the sequential write speed

Uses dd and bypasses filesystem cache for a more accurate test

Useful for testing:

- different disks' speeds
- different cables' speed with the same disk
- different ports' speeds on Macs (right ports may be slower)

I wrote this because I discovered a huge performance and estimated time to restore speed difference using
macOS Time Machine recovery while using USB 2 vs USB 3 cables with the same SanDisk Extreme Pro SSD external backup disk

WARNING: Don't re-run this on SSDs frequently as they have a limited number of writes and you'll wear the disk out
prematurely

Removes the test file upon completion or Control-C (don't Control-C multiple times or it may not remove file)

Set environment variable NODELETE to any value if you want to retain the file in the case of successful completion
for use with the adjacent script:

    disk_read_speed_sequential_dd.sh
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<directory>]"

help_usage "$@"

max_args 1 "$@"

dir="${1:-${PWD:-$(pwd)}}"
file="$dir/disk_speed_test_sequential_dd.bin"
file="${file//\/\//\/}"

#if [ -e "$file" ]; then
#    die "ERROR: file already exists, aborting for safety: $file"
#fi

trap_cmd "rm -f '$file'"

timestamp "Sequential write test to: $file"
echo >&2

# conv=sync - pads blocks to the full amount, not needed with /dev/zero which will fully pad
#dd if=/dev/zero of="$file" bs=1m count=1024
# write 4GB in higher block size to stress the disk better if it's an SSD
# oflag=direct - bypass filesystem cache for a more realistic speed test
dd if=/dev/zero of="$file" bs=64m count=64 oflag=direct

echo >&2
timestamp "Write test completed"
if [ -n "${NODELETE:-}" ]; then
    timestamp "Retaining test file: $file"
    untrap
else
    timestamp "Removing test file: $file"
fi
