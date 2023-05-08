#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-01-06 14:09:39 +0000 (Mon, 06 Jan 2020)
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

section "Checking no Git / Diff merge remnants"

if [ -n "${1:-}" ]; then
    if ! [ -d "$1" ]; then
        echo "No such file or directory $1"
        exit 1
    fi
    pushd "$1"
fi

start_time="$(start_timer)"

regex='^([<]<<<<<<|>>>>>>[>])'

echo "searching for '$regex' under $PWD:"
echo
# slow, may scan filesystem containing large files - can waste minutes of time
#if grep -IER "$regex" --devices=skip --exclude-dir={.git} . 2>/dev/null; then
if git grep -IE "$regex" . 2>/dev/null; then
    echo
    echo "FOUND Git / Diff merge remnants!"
    exit 1
fi

time_taken "$start_time"
section2 "No git / diff merge remnants found"
echo
