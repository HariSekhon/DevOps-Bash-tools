#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2016-07-25 00:17:36 +0100 (Mon, 25 Jul 2016)
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

if [ -z "$(find -L "${1:-.}" -name build.gradle)" ]; then
    return 0 &>/dev/null || :
    exit 0
fi

echo "
# ============================================================================ #
#                                  G r a d l e
# ============================================================================ #
"

if which gradle &>/dev/null; then
    find -L "${1:-.}" -name build.gradle |
    grep -v '/build/' |
    while read build_gradle; do
        echo "Validating $build_gradle"
        gradle -b "$build_gradle" -m clean build || exit $?
        echo
    done
else
    echo "Gradle not found in \$PATH, skipping gradle checks"
fi

echo
echo
