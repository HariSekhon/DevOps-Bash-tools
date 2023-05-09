#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2022-02-22 15:20:27 +0000 (Tue, 22 Feb 2022)
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
Counts the number of resources Checkov is scanning across all given repos

Useful to estimate Bridgecrew Cloud costs for all repos which are charged per resource

This can take a while to run on large directories with lots of resources

Any customization to the 'checkov' settings must use local .checkov.yaml config file in each repo root
such as which directories to scan or skip, see this working config for example:

    https://github.com/HariSekhon/Templates/blob/master/.checkov.yaml


Each given repo dir should be the root of the repo so that .checkov.yaml can be found


Uses adjacent script:

    checkov_resource_count.sh


Requires Checkov, awk and jq to be installed
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<repo_dir1> [<repo_dir2> <repo_dir3> ...]"

help_usage "$@"

min_args 1 "$@"

for dir in "$@"; do
    timestamp "Scanning Checkov resources in directory '$dir'"
    "$srcdir/checkov_resource_count.sh" "$dir"
done |
awk '{ total += $1 } END { print total }'
