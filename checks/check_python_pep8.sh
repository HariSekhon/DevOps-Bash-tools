#!/usr/bin/env bash
# shellcheck disable=SC2230
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

# shellcheck source=lib/utils.sh
. "$srcdir/lib/python.sh"

# maxdepth 2 to avoid recursing submodules which have their own checks
files="$(find_python_jython_files . -maxdepth 2)"

if [ -z "$files" ]; then
    # shellcheck disable=SC2317
    return 0 &>/dev/null ||
    exit 0
fi

section "Python PEP8 checking all Python / Jython files"

start_time="$(start_timer)"

# $sudo defined in lib/util.sh
# shellcheck disable=SC2154
type -P pep8 &>/dev/null || $sudo pip install pep8
type -P pep8
pep8 --version
echo

while read -r filename; do
    type isExcluded &>/dev/null && isExcluded "$filename" && continue
    # E265 - spaces after # - I prefer no space it makes it easier to commented code vs actual comments
    # E402 - import must be at top of file, but I like to do dynamic sys.path.append
    pep8 --show-source --show-pep8 --max-line-length=120 --ignore=E402,E265 "$filename" | more
done <<< "$files"

time_taken "$start_time"
section2 "Python PEP8 Completed Successfully"
echo
