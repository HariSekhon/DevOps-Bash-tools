#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2024-11-20 18:30:58 +0400 (Wed, 20 Nov 2024)
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
Lists duplicate INI config sections that are using the same value for a given key
in the given .ini file
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<file> <key>"

help_usage "$@"

num_args 2 "$@"

file="$1"
key="$2"

if ! [ -f "$file" ]; then
    die "ERROR: file does not exist: $file"
fi

# check the given key actually exists somewhere
if ! grep -q "^[[:space:]]*${key}[[:space:]]*=" "$file"; then
    die "ERROR: given key '$key' was not found in the file: $file"
fi

duplicate_key_values="$(
    grep "^[[:space:]]*${key}[[:space:]]*=" "$file" |
    sed 's/.*=[[:space:]]*//' |
    sort |
    uniq -d |
    sed '/^[[:space:]]*$/d'
)"

section=""

while read -r value; do
    if is_blank "$value"; then
        continue
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
        elif [[ "$line" =~ ^[[:space:]]*\[.+\] ]]; then
            section="$line"
        else
            section+="
$line"
            if [[ "$line" =~ ^[[:space:]]*${key}[[:space:]]*=[[:space:]]*${value}[[:space:]]*$ ]]; then
                found=1
            fi
        fi
    done < "$file"
done <<< "$duplicate_key_values"
