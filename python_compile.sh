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

set -u
[ -n "${DEBUG:-}" ] && set -x
srcdir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

. "$srcdir/utils.sh"

if [ -z "$(find -L "${1:-.}" -maxdepth 2 -type f -iname '*.py' -o -iname '*.jy')" ]; then
    return 0 &>/dev/null || :
    exit 0
fi

section "Compiling all Python / Jython files"
echo

if [ -n "${NOCOMPILE:-}" ]; then
    echo '$NOCOMPILE environment variable set, skipping python compile'
elif [ -n "${QUICK:-}" ]; then
    echo '$QUICK environment variable set, skipping python compile'
else
    for x in $(find -L "${1:-.}" -maxdepth 2 -type f -iname '*.py' -o -iname '*.jy'); do
        type isExcluded &>/dev/null && isExcluded "$x" && continue
        echo "compiling $x"
        python -m py_compile "$x"
    done
    section "Python Compile Completed Successfully"
    echo
fi
echo
