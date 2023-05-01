#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-09-11 15:37:03 +0100 (Fri, 11 Sep 2020)
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
Finds stuck Kubernetes jobs based on them matching all of following criteria:

1. 0 completions
2. duration is in hours or days
3. duration matches age (has been stuck since start)

Args are passed to kubectl as per normal (eg. specify -n for namespace)
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<kubectl_options>]"

help_usage "$@"

kubectl get jobs "$@" |
while read -r name completions duration age; do
    if [[ "$completions" =~ ^0 ]] &&
       [[ "$duration" =~ h|d|[[:digit:]]{3}m ]] &&
       [ "$duration" = "$age" ]; then
        echo "$name $completions $duration $age"
    elif [ "$name" = NAME ]; then
        echo "$name $completions $duration $age"
    fi
done |
column -t
