#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-03-03 17:47:02 +0000 (Tue, 03 Mar 2020)
#
#  https://github.com/HariSekhon/DevOps-Bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/HariSekhon
#

# Quick pipe script to give progress dots on stderr while you pipe or redirect > to a file
#
# eg. some_big_command | progress_dots.sh > file.txt

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x

LINES_PER_DOT="${LINES_PER_DOT:-100}"

if ! [[ "$LINES_PER_DOT" =~ ^[[:digit:]]+$ ]]; then
    echo "LINES_PER_DOT must be an integer!" >&2
    exit 1
fi

count=0

if [ $# -gt 0 ]; then
    "$@"
else
    cat
fi |
while read -r line; do
    ((count+=1))
    perl -e "if($count % $LINES_PER_DOT == 0){print STDERR '.'}"
    printf '%s\n' "$line"
done
echo >&2
