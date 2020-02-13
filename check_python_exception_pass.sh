#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2017-11-13 15:18:19 +0100 (Mon, 13 Nov 2017)
#
#  https://github.com/harisekhon/bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help improve or steer this or other code I publish
#
#  https://www.linkedin.com/in/harisekhon
#

set -eu
[ -n "${DEBUG:-}" ] && set -x
srcdir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# shellcheck source=lib/utils.sh
. "$srcdir/lib/utils.sh"

if [ -z "$(find "${1:-.}" -maxdepth 2 -type f -iname '*.py' -o -iname '*.jy')" ]; then
    return 0 &>/dev/null || :
    exit 0
fi

section "Python - finding any usage of exception pass"

start_time="$(start_timer)"

for x in $(find "${1:-.}" -maxdepth 2 -type f -iname '*.py' -o -iname '*.jy' | sort); do
    type isExcluded &>/dev/null && isExcluded "$x" && echo -n '-' && continue
    [[ "$x" =~ /test/ ]] && echo -n '-' && continue
    echo -n '.'
    if grep -E -B3 -A1 '^[[:space:]]+\bpass\b' "$x" | grep -Eq '^[^#]*\bexcept\b'; then
        echo
        grep -EHnB 5 -A1 '^[[:space:]]+\bpass\b' "$x" | grep -E -5 '^[^#]*\bexcept\b'
        echo
        echo
        echo "WARNING: $x contains 'pass'!! Check this code isn't being sloppy"
        #if ! is_CI; then
        #    exit 1
        #fi
    fi
done

time_taken "$start_time"
section2 "Python OK - no except pass usage found"
echo
