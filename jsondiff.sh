#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-04-04 17:00:20 +0100 (Sat, 04 Apr 2020)
#
#  https://github.com/HariSekhon/DevOps-Bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/HariSekhon
#

# Diffs 2 JSON files given as arguments

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x

usage(){
    echo "usage: ${0##*/} file1.json file2.json"
    exit 3
}

if ! [ $# -eq 2 ]; then
    usage
fi

for arg; do
    case "$arg" in
        -*) usage
            ;;
    esac
done

diff <(jq -S . "$1") <(jq -S . "$2")
