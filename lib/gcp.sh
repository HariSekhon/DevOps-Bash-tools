#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#  shellcheck disable=SC1090
#
#  Author: Hari Sekhon
#  Date: 2020-08-13 19:38:39 +0100 (Thu, 13 Aug 2020)
#
#  https://github.com/harisekhon/bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/harisekhon
#

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x

if is_piped || [ -n "${NO_FORMATTING:-}" ]; then
    formatting=''
else
    # want deferred expansion
    # shellcheck disable=SC2016
    formatting='"[box,title=\"$title\"]"'
fi

gcp_info(){
    local title="$1"
    shift || :
    for ((i=0; i <= ${#title}; i++)); do
        printf '='
    done
    echo
    echo "$title:"
    # eval required to interpolate $title into formatting
    eval "$@" --format="$formatting"
    echo
}
