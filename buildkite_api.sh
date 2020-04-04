#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-04-01 18:17:59 +0100 (Wed, 01 Apr 2020)
#
#  https://github.com/harisekhon/bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/harisekhon
#

set -euo pipefail

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="/path [<curl_options>]"

# shellcheck disable=SC2034
usage_description="
Queries BuildKite API, auto-populating \$BUILDKITE_TOKEN from environment and API url base for convenience

https://buildkite.com/docs/apis/rest-api

eg.

buildkite_api.sh user | jq

buildkite_api.sh organizations | jq

buildkite_api.sh organizations/hari-sekhon/pipelines | jq

buildkite_api.sh organizations/hari-sekhon/pipelines/devops-bash-tools | jq

buildkite_api.sh builds | jq

buildkite_api.sh organizations/hari-sekhon/builds | jq

buildkite_api.sh organizations/hari-sekhon/pipelines/devops-bash-tools/builds/<num> | jq

buildkite_api.sh organizations/hari-sekhon/agents | jq

buildkite_api.sh organizations/hari-sekhon/emojis | jq
"

[ -n "${DEBUG:-}" ] && set -x
srcdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck disable=SC1090
. "$srcdir/lib/utils.sh"

if [ -z "${BUILDKITE_TOKEN:-}" ]; then
    usage "BUILDKITE_TOKEN environment variable is not set (generate this from the Web UI -> Personal Settings -> API Access Tokens (https://buildkite.com/user/api-access-tokens)"
fi

if [ $# -lt 1 ]; then
    usage "no /path given to query in the API"
fi

help_usage "$@"

url_path="${1##/}"
shift

if is_curl_min_version 7.55; then
    # hide token from process list if curl version is new enough to support this trick
    curl -sSH 'Accept: application/json' -H @<(cat <<< "Authorization: Bearer $BUILDKITE_TOKEN") "https://api.buildkite.com/v2/$url_path" "$@"
else
    curl -sSH 'Accept: application/json' -H "Authorization: Bearer $BUILDKITE_TOKEN" "https://api.buildkite.com/v2/$url_path" "$@"
fi
