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
#  http://www.linkedin.com/in/harisekhon
#

set -eu
srcdir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

. "$srcdir/utils.sh"

if [ -z "$(find -L "${1:-.}" -maxdepth 2 -type f -iname '*.py' -o -iname '*.jy')" ]; then
    return 0 &>/dev/null || :
    exit 0
fi

echo "
# ============================================================================ #
#                                  P y L i n t
# ============================================================================ #
"

if [ -n "${NOPYLINT:-}" ]; then
    echo '$NOPYLINT environment variable set, skipping PyLint error checks'
elif [ -n "${QUICK:-}" ]; then
    echo '$QUICK environment variable set, skipping PyLint error checks'
else
    # TODO: make this happen in one pass as it'll be more efficient
    for x in $(find -L ${1:-.} -maxdepth 2 -type f -iname '*.py' -o -iname '*.jy'); do
        isExcluded "$x" && continue
        if which pylint &>/dev/null; then
            echo "pylint -E $x"
            echo
            pylint -E $x
            hr; echo
        fi
    done
fi
echo
