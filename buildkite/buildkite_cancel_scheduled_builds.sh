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

# shellcheck disable=SC2034
usage_description="
Cancels BuildKite scheduled builds via its API (to clear a backlog due to offline agents and just focus on new builds)

You might have to run this more than once if there are a lot of scheduled builds due to limitations with BuildKite's
API pagination not returning all results or even indicating if there are more results to return

https://buildkite.com/docs/apis/rest-api/builds
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<curl_options>]"

help_usage "$@"

"$srcdir/buildkite_api.sh" 'builds?state=scheduled' "$@" |
jq -r '.[] | [.pipeline.slug, .number, .url] | @tsv' |
while read -r name number url; do
    url="${url#https://api.buildkite.com/v2/}"
    echo -n "Cancelling $name build number $number:  "
    "$srcdir/buildkite_api.sh" "$url/cancel" -X PUT |
    jq -r '.state'
done
