#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2015-05-25 01:38:24 +0100 (Mon, 25 May 2015)
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

set +o pipefail
filelist="$(find "${1:-.}" -maxdepth 2 -type f -iname '*.pl' -o \
                                       -type f -iname '*.pm' -o \
                                       -type f -iname '*.t' |
            grep -v /templates/ | sort)"
set -o pipefail

if [ -z "$filelist" ]; then
    return 0 &>/dev/null || :
    exit 0
fi

section "Perl Syntax Checks"

start_time="$(start_timer)"

if ! type -P perl &>/dev/null; then
    echo "Perl is not installed, skipping checks"
    exit 0
fi

type -P perl
perl --version
echo

if [ -n "${NOSYNTAXCHECK:-}" ]; then
    echo "\$NOSYNTAXCHECK environment variable set, skipping perl syntax checks"
    echo
elif [ -n "${QUICK:-}" ]; then
    echo "\$QUICK environment variable set, skipping perl syntax checks"
    echo
else
    max_len=0
    for x in $filelist; do
        if [ "${#x}" -gt "$max_len" ]; then
            max_len="${#x}"
        fi
    done
    # to account for the semi colon
    ((max_len + 1))
    for filename in $filelist; do
        isExcluded "$filename" && continue
        printf "%-${max_len}s " "$filename:"
        #$perl -Tc $I_lib $filename
        # -W too noisy
        # -Mstrict - flags common DESCRIPTION / VERSION unscoped
        # -Mdiagnostics
        # shellcheck disable=SC2154
        # $perl is set in perl.sh which is included from utils.sh
        $perl -I . -Tc "$filename" 2>&1 | sed "s,^$filename ,,"
    done
    time_taken "$start_time"
    section2 "All Perl programs passed syntax check"
fi
echo
