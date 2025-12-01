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
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<directory>"

help_usage "$@"

num_args 1 "$@"

dir="$1"

for subdir in .fseventsd .Spotlight-V100; do
    if [ -d "$dir" ]; then
        timestamp "rm -rfv \"${dir:?}/${subdir:?}\""
        # defensive coding - returns an error if the variables are unset for extra safety
        # to prevent rm -rf / upon blank variables
        rm -rfv "${dir:?}/${subdir:?}"
    fi
done
if [ -f "$dir/.DS_Store" ]; then
    timestamp "rm -v \"${dir:?}/.DS_Store\""
    rm -v "${dir:?}/.DS_Store"
fi
timestamp "rmdir -v \"$dir\""
rmdir -v "$dir"
