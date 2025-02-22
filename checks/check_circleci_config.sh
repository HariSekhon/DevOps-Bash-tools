#!/usr/bin/env bash
# shellcheck disable=SC2230
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2016-01-15 00:33:52 +0000 (Fri, 15 Jan 2016)
#
#  https://github.com/HariSekhon/DevOps-Bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help improve or steer this or other code I publish
#
#  https://www.linkedin.com/in/HariSekhon
#

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=lib/utils.sh
. "$srcdir/lib/utils.sh"

# shellcheck source=lib/docker.sh
. "$srcdir/lib/docker.sh"

#return 0 &>/dev/null || :
#exit 0

section "Circle CI Config Validate"

start_time="$(start_timer)"

#if is_travis; then
#    echo "Running inside Circle CI, skipping lint check"
if is_inside_docker; then
    echo "Running inside Docker, skipping Circle lint check"
else
    if type -P circleci &>/dev/null; then
        type -P circleci
        printf "version: "
        circleci version
        echo
        find . -path '*/.circleci/config.yml' |
        while read -r config; do
            timestamp "checking CircleCI config: $config"
            circleci config validate "$config"
            echo >&2
        done
    else
        echo "WARNING: skipping Circle check as circleci command not found in \$PATH ($PATH)"
    fi
fi

echo
time_taken "$start_time"
section2 "Circle CI yaml validation succeeded"
echo
