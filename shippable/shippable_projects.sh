#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-03-24 15:36:53 +0000 (Tue, 24 Mar 2020)
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
usage_description="Returns a list of Shippable projects ids and names, or a single project name if the project id is given as an arg"
# shellcheck disable=SC2034
usage_args="[<project_id>]"

if [ -z "${SHIPPABLE_ACCOUNT_ID:-}" ]; then
    usage "SHIPPABLE_ACCOUNT_ID environment variable is not set (get this value from your Web UI Dashboard)"
fi

help_usage "$@"

project_id=""
if [ $# -gt 0 ]; then
    project_id="$1"
    shift || :
fi

if [ -n "$project_id" ] &&
   ! [[ "$project_id" =~ ^[[:alnum:]]+$ ]]; then
    usage "invalid project id '$project_id' argument specified, must be alphanumeric"
fi

jq_query_common='[.id, .sourceRepoOwner.login, .name] | @tsv'
# API returns list without project id or hashmap with project id
jq_query=".[] | $jq_query_common"
if [ -n "$project_id" ]; then
    jq_query="$jq_query_common"
fi

"$srcdir/shippable_api.sh" "/projects/$project_id?sortBy=createdAt&sortOrder=-1&ownerAccountIds=$SHIPPABLE_ACCOUNT_ID" "$@" |
jq -r "$jq_query"
