#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2017-12-28 12:24:21 +0000 (Thu, 28 Dec 2017)
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

# shellcheck source=lib/utils.sh disable=SC1091
. "$srcdir/lib/utils.sh"

section "Checking there are no SUID / GUID shell scripts"

start_time="$(start_timer)"

# shellcheck source=lib/excluded.sh
#. "$srcdir/lib/excluded.sh"

if is_mac; then
    find(){
        gfind "$@"
    }
fi

suid_guid_scripts="$(
    find "${1:-.}" -type f -iname '*.sh' -perm /4000 -o \
                   -type f -iname '*.sh' -perm /2000 |
    sort |
    tee /dev/stderr
)"

num_suid_guid="$(sed '/^[[:space:]]*$/d' <<< "$suid_guid_scripts" | wc -l | sed 's/[[:space:]]*//')"

if [ "$num_suid_guid" -gt 0 ]; then
    echo
    echo "$num_suid_guid files with suid / guid detected!"
    # allow to source, ignore if not sourced
    # shellcheck disable=SC2317
    return 1 &>/dev/null || :
    # exit otherwise
    # shellcheck disable=SC2317
    exit 1
fi

time_taken "$start_time"
section2 "SUID / GUID check passed"
echo
