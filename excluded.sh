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

# intended only to be sourced by utils.sh
#
# split from utils.sh as this is specific to this repo

set -eu
[ -n "${DEBUG:-}" ] && set -x

if ! type isExcluded &>/dev/null; then
    isExcluded(){
        local prog="$1"
        [[ "$prog" =~ ^\* ]] && return 0
        [[ "$prog" =~ ^\.\/\. ]] && return 0
        [[ "$prog" =~ ^\.[[:alnum:]] ]] && return 0
        if which git &>/dev/null; then
            commit="$(git log "$prog" | head -n1 | grep 'commit')"
            if [ -z "$commit" ]; then
                return 0
            fi
        fi
        return 1
    }
fi
