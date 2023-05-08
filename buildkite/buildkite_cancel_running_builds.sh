#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2021-06-08 10:53:10 +0100 (Tue, 08 Jun 2021)
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
Cancels BuildKite running builds via its API (to clear them and restart new later eg. after agent / environment change / fix)

https://buildkite.com/docs/apis/rest-api/builds
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<curl_options>]"

help_usage "$@"

"$srcdir/buildkite_api.sh" 'builds?state=running' "$@" |
jq -r '.[] | [.pipeline.slug, .number, .url] | @tsv' |
while read -r name number url; do
    url="${url#https://api.buildkite.com/v2/}"
    echo -n "Cancelling $name build number $number:  "
    "$srcdir/buildkite_api.sh" "$url/cancel" -X PUT |
    jq -r '.state'
done
