#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#  args: google.com
#
#  Author: Hari Sekhon
#  Date: 2026-01-15 16:40:43 -0500 (Thu, 15 Jan 2026)
#
#  https://github.com/HariSekhon/DevOps-Bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn
#  and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/HariSekhon
#

# based off urlopen.sh

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck disable=SC1090,SC1091
. "$srcdir/lib/utils.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Opens the file or url given as an arg, or first line from standard input if no arg is given

Uses the desktop environment's generic open functionally for Mac or Linux
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<url_or_file>]"

help_usage "$@"

max_args 1 "$@"

open(){
    local openers=(
        xdg-open
        gnome-open
    )
    local arg="$1"
    if is_mac; then
        open "$arg"
    else  # assume Linux
        for opener in "${openers[@]}"; do
            if type -P "$opener" &>/dev/null; then
                "$opener" "$arg"
                return 0
            fi
        done
        die "ERROR: none of the following desktop openers were found in the \$PATH:

$(for opener in "${openers[@]}"; do echo "$opener"; done)

Could not open the given file or url: $arg
"
    fi
}
export -f open

if [ $# -eq 0 ]; then
    cat
else
    echo "$1"
fi |
# head -n1 because grep -m 1 can't be trusted and sometimes outputs more matches on subsequent lines
head -n1 |
while read -r arg; do
    open "$arg"
done
