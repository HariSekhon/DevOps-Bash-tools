#!/usr/bin/env bash
# shellcheck disable=SC2230
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2016-07-25 00:17:36 +0100 (Mon, 25 Jul 2016)
#
#  https://github.com/HariSekhon/DevOps-Bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/HariSekhon
#

set -eu #o pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=lib/utils.sh
. "$srcdir/lib/utils.sh"

build_files="$(find "${1:-.}" -name build.gradle)"

if [ -z "$build_files" ]; then
    # shellcheck disable=SC2317
    return 0 &>/dev/null ||
    exit 0
fi

section "G r a d l e"

start_time="$(start_timer)"

if type -P gradle &>/dev/null; then
    type -P gradle
    gradle --version
    echo
    grep -v '/build/' <<< "$build_files" |
    sort |
    while read -r build_gradle; do
        echo "Validating $build_gradle"
        #gradle -b "$build_gradle" -m clean build || exit $?
        # Gradle 8 doesn't let you specify -b, expects build.gradle
        dir="$(dirname "$build_gradle")"
        cd "$dir"
        #gradle -b "$build_gradle" -m clean build || exit $?
        gradle -m clean build || exit $?
    done
else
    echo "Gradle not found in \$PATH, skipping gradle checks"
fi

time_taken "$start_time"
section2 "All Gradle builds passed dry run checks"
echo
