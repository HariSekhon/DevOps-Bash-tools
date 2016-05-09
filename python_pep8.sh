#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2015-05-25 01:38:24 +0100 (Mon, 25 May 2015)
#
#  https://github.com/harisekhon/bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help improve or steer this or other code I publish
#
#  https://www.linkedin.com/in/harisekhon
#

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

. "$srcdir/utils.sh"

section "Python PEP8 checking all Python / Jython files"
echo

for x in $(find "${1:-.}" -maxdepth 2 -type f -iname '*.py' -o -iname '*.jy'); do
    type isExcluded &>/dev/null && isExcluded "$x" && continue
    which pep8 &>/dev/null || sudo pip install pep8
    pep8 --show-source --show-pep8 --max-line-length=120 --ignore=E402 "$x" | more
done
section "Python PEP8 Completed Successfully"
echo
echo
