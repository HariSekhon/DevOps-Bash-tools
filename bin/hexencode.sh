#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2025-02-21 22:50:07 +0700 (Fri, 21 Feb 2025)
#
#  https://github.com/HariSekhon/DevOps-Bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/HariSekhon
#

# Quick command line Hex encoding
#
# Different to URL encoding in that urlencoding will leave dashes,
# but for Shield.io badges I need to encode the dashes to fit within each badge token

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x

if uname | grep -q Darwin; then
    sed(){
        gsed "$@"
    }
    export -f sed
fi

if [ $# -gt 0 ]; then
    echo "$@"
else
    cat
fi |
if type -P hexdump &>/dev/null; then
    hexdump -ve '/1 " %02x"' |
    sed 's/ /%/g'
elif type -P od &>/dev/null; then
    od -A n -t x1 |
    sed 's/[[:space:]]\+$//; s/[[:space:]]\+/%/g'
else
    echo "Neither 'hexdump' nor 'od' commands were found in PATH" >&2
    exit 1
fi |
sed 's/%0a$//' |
tr '[:lower:]' '[:upper:]'
echo
