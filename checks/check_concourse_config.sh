#!/usr/bin/env bash
# shellcheck disable=SC2230
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-03-21 19:21:11 +0000 (Sat, 21 Mar 2020)
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

config=".concourse.yml"

if [ -z "$(find "${1:-.}" -name "$config")" ]; then
    return 0 &>/dev/null || :
    exit 0
fi

section "C o n c o u r s e"

start_time="$(start_timer)"

if type -P fly &>/dev/null; then
    type -P fly
    fly --version
    echo
    find "${1:-.}" -name "$config" |
    while read -r config; do
        echo "Validating $config"
        fly validate-pipeline -c "$config" || exit $?
        echo
    done
else
    echo "Concourse 'fly' command not found in \$PATH, skipping concourse config checks"
fi

time_taken "$start_time"
section2 "Concourse config checks passed"
echo
