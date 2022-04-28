#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-03-02 17:53:39 +0000 (Mon, 02 Mar 2020)
#
#  https://github.com/HariSekhon/DevOps-Bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/HariSekhon
#

# fetch Wercker repo details - needed for getting Wercker CI build IDs (eg. for shields.io)

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

usage(){
    echo "${0##*/} <user>/<application>"
    exit 3
}

if [ $# -ne 1 ]; then
    usage
fi

"$srcdir/wercker_api_app.sh" "$@" |
jq -r '.id'
