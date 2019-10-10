#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2019-10-10 16:01:58 +0100 (Thu, 10 Oct 2019)
#
#  https://github.com/harisekhon/bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help improve or steer this or other code I publish
#
#  https://www.linkedin.com/in/harisekhon
#

# Rough sketch of

set -u
[ -n "${DEBUG:-}" ] && set -x
srcdir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# shellcheck disable=SC1090
. "$srcdir/lib/utils.sh"

filelist="$(find "${1:-.}" -maxdepth 2 -type f -iname '*.py')"

if [ -z "$filelist" ]; then
    echo "no Python"
    echo
    echo "usage: ${0##*/} <python_file_or_directory>"
    echo
    return 0 &>/dev/null || :
    exit 0
fi

section "Compiling and bundling Python code using PyInstaller"

start_time="$(start_timer)"

opts="-y"
if [ -d pylib ]; then
    opts="$opts --paths pylib"
fi

for x in $filelist; do
    type isExcluded &>/dev/null && isExcluded "$x" && continue
    echo "compiling => $x"
    # want opt expansion
    # shellcheck disable=SC2086
    pyinstaller $opts --hidden-import ConfigParser "$x"
    echo
done

time_taken "$start_time"
section2 "Finished PyInstaller compilation"
echo
