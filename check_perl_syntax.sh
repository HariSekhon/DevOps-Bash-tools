#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2015-05-25 01:38:24 +0100 (Mon, 25 May 2015)
#
#  https://github.com/harisekhon/nagios-plugins
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help improve or steer this or other code I publish
#
#  http://www.linkedin.com/in/harisekhon
#

set -eu
[ -n "${DEBUG:-}" ] && set -x
srcdir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

. "$srcdir/utils.sh"

if [ -z "$(find -L "${1:-.}" -maxdepth 2 -type f -iname '*.pl' -o -iname '*.pm' -o -iname '*.t')" ]; then
    return 0 &>/dev/null || :
    exit 0
fi

section "Perl Syntax Checks"

if [ -n "${NOSYNTAXCHECK:-}" ]; then
    echo '$NOSYNTAXCHECK environment variable set, skipping perl syntax checks'
elif [ -n "${QUICK:-}" ]; then
    echo '$QUICK environment variable set, skipping perl syntax checks'
else
    for x in $(find -L "${1:-.}" -maxdepth 2 -type f -iname '*.pl' -o -iname '*.pm' -o -iname '*.t'); do
        isExcluded "$x" && continue
        #printf "%-50s" "$x:"
        #$perl -Tc $I_lib $x
        # -W too noisy
        perl -I . -Tc $x
    done
    section "All Perl programs passed syntax check"
    echo
fi
echo
