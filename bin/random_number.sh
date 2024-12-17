#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#  args: 100 110
#
#  Author: Hari Sekhon
#  Date: 2024-12-17 12:28:21 +0700 (Tue, 17 Dec 2024)
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
Prints a random integer between two integer arguments (inclusive)
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<min> <max>"

help_usage "$@"

num_args 2 "$@"

min="$1"
max="$2"

if ! is_int "$min"; then
    usage "First arg is not an integer: $min"
elif ! is_int "$max"; then
    usage "Second arg is not an integer: $max"
fi

#random_number="$(shuf -i "$min-$max" -n 1)"

random_number="$((RANDOM % (max - min + 1) + min))"

echo "$random_number"
