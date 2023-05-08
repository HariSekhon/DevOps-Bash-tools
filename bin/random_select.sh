#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2016-08-01 17:53:24 +0100 (Mon, 01 Aug 2016)
#
#  https://github.com/HariSekhon/DevOps-Bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/HariSekhon
#

set -eu
[ -n "${DEBUG:-}" ] && set -x


if [ -z "$*" ]; then
    echo "usage: ${0##*/} arg1 arg2 arg3 ..."
    exit 1
fi

i=0
for x in "$@"; do
    a[$i]="$x"
    ((i + 1))
done

num=${#@}

selected=$((RANDOM % num))

echo "${a[$selected]}"
