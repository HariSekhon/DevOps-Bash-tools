#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2018-08-16 13:47:32 +0100 (Thu, 16 Aug 2018)
#
#  https://github.com/HariSekhon/DevOps-Bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/HariSekhon
#

# Checks we don't get any bash array variables getting overwritten
#
# Written for test_anonymize.sh in DevOps Python & Perl Tools repos which makes heavy use of bash array variables for tests

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=lib/utils.sh
. "$srcdir/lib/utils.sh"

if [ $# -eq 0 ]; then
    if [ -z "$(find "${1:-.}" -type f -iname '*.sh')" ]; then
        return 0 &>/dev/null || :
        exit 0
    fi
fi

section "Bash Array Checks (Duplicate Indices and Syntax Errors)"

check_bash_arrays(){
    local filename="$1"
    echo -n "checking bash arrays:  $1"
    set +eo pipefail
    dups="$(grep -o '^[[:space:]]*[[:alnum:]]\+[[[:digit:]]\+]=' "$filename" | sed 's/[[:space:]]*//' | sort | uniq -d)"
    early_equals="$(grep -o '[[:alnum:]]\+=[[[:digit:]]\+]=' "$filename")"
    set -eo pipefail
    if [ -n "$dups" ]; then
        echo " => Duplicates detected!"
        echo "$dups"
        exit 1
    elif [ -n "$early_equals" ]; then
        echo " => Invalid array definition detected!"
        echo "$early_equals"
        exit 1
    else
        echo " => OK"
    fi
}

recurse_dir(){
    for x in $(find "${1:-.}" -type f -iname '*.sh' | sort); do
        # TODO: consider skipping shell scripts which don't contain '#!.*bash'
        isExcluded "$x" && continue
        check_bash_arrays "$x"
    done
}

start_time="$(start_timer)"

if [ $# -gt 0 ]; then
    for x in "$@"; do
        if [ -d "$x" ]; then
            recurse_dir "$x"
        else
            check_bash_arrays "$x"
        fi
    done
else
    recurse_dir .
fi

time_taken "$start_time"
section2 "All Bash programs passed array duplicates check"
echo
