#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2016-01-23 17:19:22 +0000 (Sat, 23 Jan 2016)
#
#  https://github.com/harisekhon/bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback
#
#  https://www.linkedin.com/in/harisekhon
#

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

. "$srcdir/utils.sh"

section "Running Test Scripts"

date
start_time="$(date +%s)"
echo

scripts="$(find "${1:-.}" -iname 'test*.sh' | sort -f)"

for script in $scripts; do
    date
    script_start_time="$(date +%s)"
    echo
    ./$script
    echo
    date
    echo
    script_end_time="$(date +%s)"
    # if start and end time are the same let returns exit code 1
    let script_time_taken=$script_end_time-$script_start_time || :
    echo "Completed in $script_time_taken secs"
done

echo
date
echo
end_time="$(date +%s)"
# if start and end time are the same let returns exit code 1
let time_taken=$end_time-$start_time || :
echo "All Test Scripts Completed in $time_taken secs"
echo
section2 "Test Scripts Completed"
echo
echo
