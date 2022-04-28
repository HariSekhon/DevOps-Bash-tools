#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-08-17 20:21:43 +0100 (Mon, 17 Aug 2020)
#
#  https://github.com/HariSekhon/DevOps-Bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/HariSekhon
#

# designed to be included from utils.sh

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x

if ! is_mac; then
    return
fi

if ! type tac &>/dev/null; then
    tac(){
        gtac "$@"
    }
fi
