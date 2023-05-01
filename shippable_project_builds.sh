#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-04-15 17:29:40 +0100 (Wed, 15 Apr 2020)
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

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<project_id> [<curl_options>]"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_description="Returns recent Shippable build results for a given project

Specify the project ID as the first argument or have \$SHIPPABLE_PROJECT_ID environment variable defined

This works for free accounts whereas the adjacent shippable_builds.sh requires a paid account

This is the same API endpoints that shields.io uses for it's badges

The statusCode field returned has integers that correspond to statuses

http://docs.shippable.com/ci/build_status/
"

SHIPPABLE_PROJECT_ID="${1:-${SHIPPABLE_PROJECT_ID:-}}"

check_env_defined SHIPPABLE_PROJECT_ID

help_usage "$@"

# this will enforce a $SHIPPABLE_TOKEN which isn't necessary as this is a public endpoint
#"$srcdir/shippable_api.sh" "/projects/$SHIPPABLE_PROJECT_ID/branchRunStatus" "$@"
curl -sSH 'Accept: application/json' "https://api.shippable.com/projects/$SHIPPABLE_PROJECT_ID/branchRunStatus" "$@"
#jq -r "$jq_query"
