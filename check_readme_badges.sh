#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-03-26 02:03:33 +0000 (Thu, 26 Mar 2020)
#
#  https://github.com/harisekhon/bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help improve or steer this or other code I publish
#
#  http://www.linkedin.com/in/harisekhon
#

# Checks for duplicates badge lines, assuming one badge per line as per std layout in headers across all my repos (more git / diff friendly)

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# shellcheck source=lib/utils.sh
. "$srcdir/lib/utils.sh"

section "Checking README badges for duplicates and incorrect links"

start_time="$(start_timer)"

echo "checking for duplicates:"
echo

# uniq -d will cause silent pipe failure without dups otherwise
set +eo pipefail
duplicates="$(
    "$srcdir/git_foreach_repo.sh" "grep -Eho '\[\!\[.*\]\(.*\)\]\(.*\)' README.md" |
    sort |
    uniq -d |
    grep -v -e 'STATUS.md' \
            -e 'harisekhon/github' \
            -e 'harisekhon/centos-github' \
            -e 'StarTrack' \
            -e 'STARCHARTS.md' \
            -e 'LinkedIn' \
            -e 'Spotify' \
            -e 'AWS Athena' \
            -e 'MySQL' \
            -e 'PostgreSQL' \
            -e 'MariaDB' \
            -e 'TeamCity' \
            -e '^=*$'
)"
set -eo pipefail

github_dir="$(dirname "$srcdir")"

while read -r line; do
    if [ -z "${line// }" ]; then
        continue
    fi
    grep -F --color=yes "$line" "$github_dir"/*/README.md
    echo
done <<< "$duplicates"

if [ -n "$duplicates" ]; then
    exit 1
else
    echo "No duplicate badge lines found"
    echo
fi

time_taken "$start_time"
section2 "README badge checks passed"
echo
