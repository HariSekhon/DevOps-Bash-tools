#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-08-15 12:55:07 +0100 (Sat, 15 Aug 2020)
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
For each line passed in via standard input, checks the given file argument and appends each line that doesn't already exist within the file

This is re-evaluated for each line, so acts as a 'uniq' filter for input lines too

See vagrant/provision.sh for an example of this in use
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<filename>"

help_usage "$@"

min_args 1 "$@"

filename="$1"

while read -r line; do
    # if file doesn't exist will append to create it
    grep -Fxq "$line" "$filename" 2>/dev/null ||
    echo "$line" >> "$filename"
done
