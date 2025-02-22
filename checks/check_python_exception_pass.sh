#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2017-11-13 15:18:19 +0100 (Mon, 13 Nov 2017)
#
#  https://github.com/HariSekhon/DevOps-Bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help improve or steer this or other code I publish
#
#  https://www.linkedin.com/in/HariSekhon
#

set -eu
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=lib/utils.sh
. "$srcdir/lib/utils.sh"

# shellcheck source=lib/utils.sh
. "$srcdir/lib/python.sh"

# maxdepth 2 to avoid recursing submodules which have their own checks
files="$(find_python_jython_files . -maxdepth 2)"

if [ -z "$files" ]; then
    # shellcheck disable=SC2317
    return 0 &>/dev/null ||
    exit 0
fi

section "Python - finding any usage of exception pass"

start_time="$(start_timer)"

while read -r filename; do
    type isExcluded &>/dev/null && isExcluded "$filename" && echo -n '-' && continue
    [[ "$filename" =~ /test/ ]] && echo -n '-' && continue
    echo -n '.'
    if grep -E -B3 -A1 '^[[:space:]]+\bpass\b' "$filename" | grep -Eq '^[^#]*\bexcept\b'; then
        echo
        grep -EHnB 5 -A1 '^[[:space:]]+\bpass\b' "$filename" | grep -E -5 '^[^#]*\bexcept\b'
        echo
        echo
        echo "WARNING: $filename contains 'pass'!! Check this code isn't being sloppy"
        #if ! is_CI; then
        #    exit 1
        #fi
    fi
done <<< "$files"

time_taken "$start_time"
section2 "Python OK - no except pass usage found"
echo
