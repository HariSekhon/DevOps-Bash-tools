#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2016-01-09 18:50:56 +0000 (Sat, 09 Jan 2016)
#
#  https://github.com/harisekhon/bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help improve or steer this or other code I publish
#
#  http://www.linkedin.com/in/harisekhon
#

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

echo "checking for whitespace only lines"

. "$srcdir/excluded.sh"

found=0
for filename in $(find "${1:-.}" -type f | grep -vf "$srcdir/whitespace_ignore.txt"); do
    isExcluded "$filename" && continue
    grep -Hn '^[[:space:]]\+$' "$filename" && found=1 || :
done
if [ $found == 1 ]; then
    echo "Whitespace only lines detected!"
    return 1 &>/dev/null || :
    exit 1
fi
echo "No whitespace only lines found"
echo
