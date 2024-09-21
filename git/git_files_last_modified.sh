#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-07-18 08:40:45 +0100 (Sat, 18 Jul 2020)
#
#  https://github.com/HariSekhon/DevOps-Bash-tools
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

# shellcheck disable=SC2034
usage_description="
For each file or directory argument given, finds the last modified date in the git log and orders the output descending

If no arguments are given, assumes to use \$PWD

Requires git to be in the \$PATH
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<files_or_dirs>]"

# shellcheck disable=SC1090,SC1091
. "$srcdir/lib/utils.sh"

help_usage "$@"

#min_args 1 "$@"

unset GIT_PAGER

for dir in "${@:-.}"; do
    # faster & more efficient but git log format doesn't have filename in format string
    #git ls-files -z "$dir" |
    #xargs -0 -L 1 git log --format="%ai %H"
    if [ -n "${VERBOSE:-}" ]; then
        echo -n "iterating $dir " >&2
    fi
    # works for files too
    git ls-files "$dir" |
    while read -r filename; do
        if [ -n "${VERBOSE:-}" ]; then
            echo -n '.' >&2
        fi
        # aI - 2020-07-17T21:52:55+01:00
        # ai - 2020-07-17 21:52:55 +0100
        # escape % in filename to come out literally
        name="${filename//%/%%}"
        git log --format="%ai   %H  $name" "$filename"
    done
    if [ -n "${VERBOSE:-}" ]; then
        echo >&2
    fi
done |
sort -r
