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

fio_config="$srcdir/disk-read-random.fio"

# shellcheck disable=SC2034,SC2154
usage_description="
Runs a random I/O read test from the current or given directory in order to test the random read speed

Uses fio with the settings found in: $fio_config

Useful for testing:

- different disks' speeds
- different cables' speed with the same disk
- different ports' speeds on Macs (right ports may be slower)

I wrote this because I discovered a huge performance and estimated time to restore speed difference using
macOS Time Machine recovery while using USB 2 vs USB 3 cables with the same SanDisk Extreme Pro SSD external backup disk
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<directory>]"

help_usage "$@"

max_args 1 "$@"

dir="${1:-${PWD:-$(pwd)}}"

cd "$dir"

timestamp "Random read test in directory: $dir"
echo >&2

fio "$fio_config"

echo >&2
timestamp "Random read test completed"
