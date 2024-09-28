#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2024-09-28 01:50:14 +0100 (Sat, 28 Sep 2024)
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
Tries to find if a lockfile is used in the given or current working directory
by taking snapshots of the file list before and after a prompt in which you should open/close an application
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<dir>]"

help_usage "$@"

max_args 1 "$@"

dir="${1:-.}"

if ! [ -d "$dir" ]; then
    usage "Non-existent directory given: $dir"
fi

timestamp "Taking 'before' file listing snapshot"
filelist_before="$(find "$dir" -type f)"
echo >&2

read -r -p 'Press Enter after opening/closing an application to take another snapshot to see if any files have changed'

timestamp "Taking 'after' file listing snapshot"
filelist_after="$(find "$dir" -type f)"
echo >&2

timestamp "Comparing File Listing Snapshots"
echo >&2

# so many ugly solutions to only getting lines changed and nothing else
# if you have a more elegant solution please send it to me
filelist_diff="$(
    diff -u <(echo "$filelist_before") <(echo "$filelist_after") |
    sed -n '/^[+-]/ p' |
    # diff fails the pipeline on non-zero exit code if any difference found
    sed '
        /^[+-]\{3\}/d ;
        s/^[+-]//;
    ' |
    while read -r filename; do
        readlink -f "$filename"
    done || :
)"

if [ -n "$filelist_diff" ]; then
    timestamp "File existence changes (may or may not be lockfiles):"
    echo >&2
    echo "$filelist_diff"
else
    timestamp "No file existence changes found between snapshots"
fi
