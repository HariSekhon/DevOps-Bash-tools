#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2022-07-11 12:18:21 +0100 (Mon, 11 Jul 2022)
#
#  https://github.com/HariSekhon/DevOps-Bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/HariSekhon
#

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck disable=SC1090,SC1091
. "$srcdir/lib/utils.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Checks all files in the Git \$PWD downwards for commands like cp and mv have double dashes before taking args
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<dir>]"

help_usage "$@"

#min_args 1 "$@"

check(){
    local cmd="$1"
    command git grep -E "^[^#]*\\<$cmd[[:space:]]+" |
    grep -v -e '--' \
            -e "${0##*/}:" \
            -e "alias $cmd" \
            -e '\.gitconfig:' \
            -e '\.gitignore:' \
            -e '\.conf:' \
    || :
}

for cmd in cp mv rm ln; do
    check "$cmd"
done
