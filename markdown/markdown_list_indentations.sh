#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2025-02-24 15:08:43 +0700 (Mon, 24 Feb 2025)
#
#  https///github.com/HariSekhon/DevOps-Bash-tools
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
Prefixes number of spaces before each list item for comparison to MarkdownLint MD005 inconsistent list indentation error
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<markdown_files>"

help_usage "$@"

min_args 1 "$@"

for filename; do
    # shellcheck disable=SC2016,SC2001
    cat -n "$filename" |
    # not expressions - false positive
    sed '/[[:space:]]```/,/[[:space:]]```/d' |
    # strip out oneline html comment because next sed will strip to end of file otherwise
    sed '/<!--.*-->/d;' |
    # strip out <!-- commented out --> sections
    sed '/<!--/,/-->/d' |
    sed "s/^[[:space:]]*/$filename /" |
    # match any line in format:
    #
    #   <filename_non_space> <line_number> - list item
    awk '/^[^[:space:]]+[[:space:]][[:digit:]]+[[:space:]][[:space:]]*-/ {print}' |
    while read -r line; do
        sed "s/^${filename}[[:space:]]\+[[:digit:]]\+[[:space:]]//" <<< "$line" |
        # print the number of spaces before list items
        awk '{print length($0) - length(substr($0, match($0, /[^ ]/)))}' |
        #tr -d '\n'
        tr '\n' ' '
        echo "$line"
    done
done
