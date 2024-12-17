#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#  args: one two three
#
#  Author: Hari Sekhon
#  Date: 2016-08-01 17:53:24 +0100 (Mon, 01 Aug 2016)
#
#  https://github.com/HariSekhon/DevOps-Bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/HariSekhon
#

set -eu
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck disable=SC1090,SC1091
. "$srcdir/lib/utils.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Prints one of the arguments via random selection
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<arg1> <arg2> [<arg3> ...]"

help_usage "$@"

min_args 2 "$@"

index=0

declare -a arg_array

for arg in "$@"; do
    log "Saving arg' $arg' at index '$index'"
    arg_array[index]="$arg"
    ((index += 1))
done

num_args="${#@}"

selected_index="$((RANDOM % num_args))"

log "Selecting arg index $selected_index"
echo "${arg_array[$selected_index]}"
