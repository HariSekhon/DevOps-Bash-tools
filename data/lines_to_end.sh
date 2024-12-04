#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2024-12-05 01:05:31 +0700 (Thu, 05 Dec 2024)
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
Filters lines matching the given regex in a given file or stdin and outputs them at the end of stdout

Used by my .vimrc to push my header links and similar down to the bottom for URL view pop-up to prioritize 3rd party docuementation links

To enforce the regex matching with case sensitivity:

    export IGNORECASE=0
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<ere_regex> [<file_or_stdin>]"

help_usage "$@"

min_args 1 "$@"
max_args 2 "$@"

regex="$1"
arg="${2:-}"

ignorecase=1  # true

# testing expected value instead of passing to awk for safety
if [ "${IGNORECASE:-}" = 0 ]; then
    ignorecase=0  # false
fi

if [ $# -eq 1 ]; then
    cat
elif [ -f "$arg" ]; then
    cat "$arg"
else
    echo "$arg"
fi |
# IGNORECASE requires gawk, not BSD awk, is mapped in lib/utils.sh
awk -v regex="$regex" \
    -v IGNORECASE="$ignorecase" \
'
    $0 ~ regex {
        matches[++m] = $0
        next
    }
    {
        print
    }
    END {
        for (i = 1; i <= m; i++) print matches[i]
    }
'
