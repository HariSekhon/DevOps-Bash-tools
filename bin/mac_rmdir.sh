#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2025-11-30 23:19:03 -0600 (Sun, 30 Nov 2025)
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

# Test:
#
#   mkdir -v /tmp/testdir
#   mkdir -v /tmp/testdir/.fseventsd
#   mkdir -v /tmp/testdir/.Spotlight-V100
#   touch -v /tmp/testdir/.DS_Store
#
#   mac_rmdir.sh /tmp/testdir

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck disable=SC1090,SC1091
. "$srcdir/lib/utils.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Safely delete a directory on Mac only if it is empty of actual data,
by first removing macOS hidden metadata files and dirs such as:

- .fseventsd/
- .Spotlight-V100/
- .DS_Store

You can combine with the find command to clean out an empty directory tree:

    find . -type d -exec "$srcdir/mac_rmdir.sh" {} \;

Used by adjacent mv.sh script
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<directory>"

help_usage "$@"

num_args 1 "$@"

dir="$1"

metadata_dirs="
.fseventsd
.Spotlight-V100
"

while read -r subdir; do
    if is_blank "$subdir"; then
        continue
    fi
    if [ -d "$dir" ]; then
        timestamp "rm -rfv \"${dir:?}/${subdir:?}\""
        # defensive coding - returns an error if the variables are unset for extra safety
        # to prevent rm -rf / upon blank variables
        rm -rfv "${dir:?}/${subdir:?}"
    fi
done <<< "$metadata_dirs"

if [ -f "$dir/.DS_Store" ]; then
    timestamp "rm -fv \"${dir:?}/.DS_Store\""
    rm -fv "${dir:?}/.DS_Store"
fi

timestamp "rmdir -v \"$dir\""
rmdir -v "$dir"
