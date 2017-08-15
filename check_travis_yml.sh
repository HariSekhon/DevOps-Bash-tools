#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2016-01-15 00:33:52 +0000 (Fri, 15 Jan 2016)
#
#  https://github.com/harisekhon/bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help improve or steer this or other code I publish
#
#  https://www.linkedin.com/in/harisekhon
#

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

. "$srcdir/utils.sh"
. "$srcdir/docker.sh"

#return 0 &>/dev/null || :
#exit 0

section "Travis CI Yaml Lint Check"

date
start_time="$(date +%s)"
echo

if is_travis; then
    echo "Running inside Travis CI, skipping lint check"
elif is_inside_docker; then
    echo "Running inside Docker, skipping lint check"
else
    # sometimes ~/.gem/ruby/<version>/bin may not be in $PATH but this succeeds anyway if hashed in shell
    #which travis &>/dev/null ||
    type travis &>/dev/null ||
        gem install travis --no-rdoc --no-ri
    travis lint
fi
echo
date
echo
end_time="$(date +%s)"
# if start and end time are the same let returns exit code 1
let time_taken=$end_time-$start_time || :
echo "Completed in $time_taken secs"
echo
section2 "Travis CI yaml validation succeeded"
echo
echo
