#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-10-06 18:59:32 +0100 (Tue, 06 Oct 2020)
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
Opens the given image file using whatever available tool is found on Linux or Mac

Used by:

    - ./image_join_stack.sh - to automatically open the stacked image
    - ../git/git_graph_commits_per_month.sh - to automatically open the generated bar chart
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<image_file>"

help_usage "$@"

num_args 1 "$@"

image="${1:-}"

# Linux commands - will be tried in this order
tools=(xdg-open gnome-open eog feh display gthumb)

if is_mac; then
    open "$image"
else  # assume Linux
    found=0
    for tool in "${tools[@]}"; do
        if type -P "$tool" &>/dev/null; then
            found=1
            xdg-open "$image" &
            break
        fi
    done
    if [ "$found" != 1 ]; then
        die "ERROR: none of the following tools to open image found: ${tools[*]}"
    fi
fi
