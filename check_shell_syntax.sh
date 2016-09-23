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

if [ -z "$(find -L "${1:-.}" -type f -iname '*.sh')" ]; then
    return 0 &>/dev/null || :
    exit 0
fi

echo "
# ============================================================================ #
#                            S h e l l   S y n t a x
# ============================================================================ #
"

for x in $(find -L "${1:-.}" -type f -iname '*.sh'); do
    echo -n "checking shell syntax: $x"
    bash -n "$x"
    echo " => OK"
done
echo
echo
