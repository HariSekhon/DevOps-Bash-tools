#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2021-12-30 12:38:43 +0000 (Thu, 30 Dec 2021)
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
Prints a list of unique characters in a string

Useful to check large strings like \$PATH for characters that may be causing a regex match failure

Works like a standard unix filter program - string is read from a file argument or passed via stdin
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<file>]"

help_usage "$@"

# need GNU switches
if is_mac; then
    od(){
        command god "$@"
    }
fi

# -c printable characters or backslash escapes
# -v don't suppress duplicates with a *, we will post process them with sort
# -w1 only output 1 char per line so we can post process with sort, can be no space between the -w and 1 otherwise it'll try to read the 1 as a file argument
od -cv -A none -w1 "$@" |
sort -bu
