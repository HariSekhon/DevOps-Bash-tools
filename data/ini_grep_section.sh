#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2024-11-24 04:19:14 +0400 (Sun, 24 Nov 2024)
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
. "$srcdir/lib/aws.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Prints the named section from a given .ini file to stdout
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<section> <file>"

help_usage "$@"

num_args 2 "$@"

section="$1"
file="$2"

if ! [ -f "$file" ]; then
    die "ERROR: file does not exist: $file"
fi

found=0

while read -r line; do
    if is_blank "$line"; then
        if [ "$found" = 1 ]; then
            echo "$section"
            section=""
            echo
            found=0
        fi
        continue
    elif [[ "$line" =~ ^[[:space:]]*\[$section\] ]]; then
        section="$line"
        found=1
    elif [ "$found" = 1 ]; then
        section+="
$line"
    fi
done < "$file"

# print if we hit end of file
if [ "$found" = 1 ]; then
    echo "$section"
    section=""
    echo
    found=0
fi
