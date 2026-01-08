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

path="${1:-/}"

while read -r snapshot_timestamp; do
    sudo tmutil deletelocalsnapshots "$snapshot_timestamp"
done < <(
    tmutil listlocalsnapshots "$path" |
    awk -F. '{print $4}'
)
