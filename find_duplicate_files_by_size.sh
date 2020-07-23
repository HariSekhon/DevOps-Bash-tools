#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-07-23 12:31:21 +0100 (Thu, 23 Jul 2020)
#
#  https://github.com/harisekhon/bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/harisekhon
#

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck disable=SC2034
usage_description="
Finds duplicate files by file size in bytes

For a much more sophisticated duplicate file finder utilizing size, checksums, basenames and
even partial basenames via regex match see

find_duplicate_files.py

in the DevOps Python tools repo https://github.com/harisekhon/devops-python-tools)
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<dir1> <dir2> ...]"

# shellcheck disable=SC1090
. "$srcdir/lib/utils.sh"

help_usage "$@"

last_size=""
last_filename=""
last_printed=0

while read -r size filename; do
    if [ "$size" = "$last_size" ]; then
        if [ "$last_printed" = 0 ]; then
            printf '%s\t%s\n' "$last_size" "$last_filename"
        fi
        printf '%s\t%s\n' "$size" "$filename"
        last_printed=1
    else
        last_printed=0
    fi
    last_size="$size"
    last_filename="$filename"
done < <(for dir in "${@:-$PWD}"; do find "$dir" -type f -print0; done | xargs -0 du -a | sort -k1n)
