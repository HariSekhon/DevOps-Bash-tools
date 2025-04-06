#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2025-04-06 22:12:20 +0800 (Sun, 06 Apr 2025)
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
Returns zero if given file(s) don't have uncommitted changes to Git, either staged or unstaged

Useful to be able to iterate over git files with in-place edits only if safe to do so
without other uncommitted changes that would be at risk of being lost
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<files>"

help_usage "$@"

min_args 1 "$@"

exitcode=0

for filename; do
    if ! [ -f "$filename" ]; then
        die "File not found: $filename"
    fi
    dirname="$(dirname "$filename")"
    basename="${filename##*/}"
    cd "$dirname"
    if ! git status --porcelain "$basename" | grep .; then
        echo "No uncommited changes: $filename"
    else
        exitcode=1
        echo "UNCOMMITTED changes discovered: $filename"
    fi
    cd - >/dev/null
done

exit "$exitcode"
