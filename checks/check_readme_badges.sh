#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-03-26 02:03:33 +0000 (Thu, 26 Mar 2020)
#
#  https://github.com/HariSekhon/DevOps-Bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help improve or steer this or other code I publish
#
#  https://www.linkedin.com/in/HariSekhon
#

# Checks for duplicates badge lines, assuming one badge per line as per std layout in headers across all my repos (more git / diff friendly)

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=lib/utils.sh
. "$srcdir/lib/utils.sh"

section "Checking README badges for duplicates and incorrect links"

ignored_lines_regex="
STATUS.md
harisekhon/github
harisekhon/centos-github
StarTrack
STARCHARTS.md
LinkedIn
Spotify
AWS Athena
MySQL
PostgreSQL
MariaDB
TeamCity
^=*$
https://aws.amazon.com
https://sonarcloud.io/dashboard
https://hub.docker.com/
https://img.shields.io/badge/
https://github.com/HariSekhon/[[:alnum:]-]*$
"

start_time="$(start_timer)"

echo "checking for duplicates:"
echo

# uniq -d will cause silent pipe failure without dups otherwise
set +eo pipefail
# want splitting for args
# shellcheck disable=SC2046
duplicates="$(
    {
    # exact README lines
    # shellcheck disable=SC1117
    "$srcdir/../git/git_foreach_repo.sh" "grep -Eho '\[\!\[.*\]\(.*\)\]\(.*\)' README.md" |
    sort |
    uniq -d

    # any URLs
    #"$srcdir/../git/git_foreach_repo.sh" "grep -Eho '\[\!\[.*\]\(.*\)\]\(.*\)' README.md" |
    #grep -Eo '(http|https)://[a-zA-Z0-9./?=_%:#&,+-]*' |
    #sort |
    #uniq -d
    } |
    grep -vi $(IFS=$'\n'; for line in $ignored_lines_regex; do [[ "$line" =~ ^[[:space:]]*$ ]] && continue; printf "%s" " -e '$line'"; done)
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
