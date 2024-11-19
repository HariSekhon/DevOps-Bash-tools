#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2024-11-19 18:48:29 +0400 (Tue, 19 Nov 2024)
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
Reverts the first line that matches a given regex from the Git head commit's version of the same line number

Useful to revert some changes caused by over zealous sed'ing scripts, where you want to cherry-pick revert a single line change

Only reverts the first matching line for safety in case you do something stupid like passing . and end up losing all uncommitted changes
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<file> <ere_regex>"

help_usage "$@"

min_args 2 "$@"

file="$1"
regex="$2"

timestamp "Determining line number in file '$file' that matches regex: $regex"
line_number="$(grep -En "$regex" "$file" | head -n1 | cut -d: -f1 || :)"

if ! is_int "$line_number"; then
    die "Failed to find line matching regex: $regex"
fi

timestamp "Matched line number: $line_number"

timestamp "Determining original line from HEAD revision"
original_line=$(git show HEAD:"$file" | sed -n "${line_number}p")
if is_blank "$original_line"; then
    die "Failed to find original line in HEAD revision matching line number: $line_number"
fi
timestamp "Original line found: $original_line"

original_line="${original_line//\//\\/}"
original_line="${original_line//\!/\\!}"
original_line="${original_line//\&/\\&}"

timestamp "Replacing line number $line_number"
sed -i "${line_number}s/.*/$original_line/" "$file"
timestamp "Replaced line $line_number from HEAD revision"
