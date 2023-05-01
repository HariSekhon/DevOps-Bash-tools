#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-04-01 18:33:42 +0100 (Wed, 01 Apr 2020)
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
usage_description="
Lists BuildKite running builds via its API

https://buildkite.com/docs/apis/rest-api/builds
"

# shellcheck disable=SC2034
usage_args="[<curl_options>]"

help_usage "$@"

"$srcdir/buildkite_api.sh" 'builds?state=running' "$@" |
jq -r '.[] | [.pipeline.slug, .branch, .number, .commit, .created_at, .jobs[0].agent.name] | @tsv' |
#while read -r name branch number commit created agent; do
#    commit="${commit:0:8}"
#    echo "$name $branch $number $commit $created $agent"
#done |
sed 's/\([[:space:]][[:alnum:]]\{8\}\)[[:alnum:]]\{32\}[[:space:]]/\1 /' |
column -t
