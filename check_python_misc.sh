#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2016-02-16 17:08:18 +0000 (Tue, 16 Feb 2016)
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
    return 0 &>/dev/null || :
    exit 0
fi

section "Python - finding miscellaneous code issues (calling quit(), self.self references)"

start_time="$(start_timer)"

exitcode=0

check(){
    local msg="$1"
    local regex="$2"
    local filename="$3"
    if grep -Eq "$regex" "$filename"; then
        echo
        grep -E "$regex" "$filename"
        echo
        echo
        echo "ERROR: $filename contains $msg!! Typo?"
        exitcode=1
    fi
}

while read -r filename; do
    type isExcluded &>/dev/null && isExcluded "$filename" && echo -n '-' && continue
    echo -n '.'
    check "quit() calls" '^[^#\.]*\bquit\b' "$filename"
    check "self.self references" '^[^#]*\bself\.self\b' "$filename"
    #check "'assert'!! This could be disabled at runtime by PYTHONOPTIMIZE=1 / -O / -OO and should not be used" '^[[:space:]]+\bassert\b' "$filename"
done <<< "$files"

if [ $exitcode != 0 ]; then
    exit $exitcode
fi

time_taken "$start_time"
section2 "Python OK - miscellaneous checks passed"
echo
