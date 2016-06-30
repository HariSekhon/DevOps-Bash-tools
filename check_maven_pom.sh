#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2016-06-30 14:46:43 +0100 (Thu, 30 Jun 2016)
#
#  https://github.com/harisekhon/bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/harisekhon
#

set -eu #o pipefail
[ -n "${DEBUG:-}" ] && set -x

if [ -z "$(find -L "${1:-.}" -name pom.xml)" ]; then
    return 0 &>/dev/null || :
    exit 0
fi

echo "
# ============================================================================ #
#                                   M a v e n
# ============================================================================ #
"

if which mvn &>/dev/null; then
    find -L "${1:-.}" -name pom.xml |
    grep -v '/target/' |
    while read pom; do
        echo "Validating $pom"
        mvn validate -f "$pom" || exit $?
        echo
    done
else
    echo "Maven not found in \$PATH, skipping maven pom checks"
fi

echo
echo
