#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2016-01-22 20:54:53 +0000 (Fri, 22 Jan 2016)
#
#  https://github.com/harisekhon/nagios-plugins
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback
#
#  https://www.linkedin.com/in/harisekhon
#

# This really only checks basic syntax, if you're made command errors this won't catch it

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

. "$srcdir/utils.sh"

if [ -z "$(find -L "${1:-.}" -type f -iname '*.sh')" ]; then
    return 0 &>/dev/null || :
    exit 0
fi

section "Shell Syntax Checks"

date
start_time="$(date +%s)"
echo

for x in $(find -L "${1:-.}" -type f -iname '*.sh'); do
    isExcluded "$x" && continue
    echo -n "checking shell syntax: $x"
    bash -n "$x"
    echo " => OK"
done

echo
date
echo
end_time="$(date +%s)"
# if start and end time are the same let returns exit code 1
let time_taken=$end_time-$start_time || :
echo "Completed in $time_taken secs"
echo
section2 "All Shell programs passed syntax check"
echo
