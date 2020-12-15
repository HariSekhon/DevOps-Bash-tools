#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#  args: user | jq
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
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck disable=SC1090
. "$srcdir/lib/utils.sh"

# shellcheck disable=SC2034
usage_description="
Queries BuildKite API, auto-populating \$BUILDKITE_TOKEN from environment and API url base for convenience

https://buildkite.com/docs/apis/rest-api

Examples:

    ${0##*/} user | jq

    ${0##*/} organizations | jq

    ${0##*/} organizations/hari-sekhon/pipelines | jq

    ${0##*/} organizations/hari-sekhon/pipelines/devops-bash-tools | jq

    ${0##*/} builds | jq

    ${0##*/} organizations/hari-sekhon/builds | jq

    ${0##*/} organizations/hari-sekhon/pipelines/devops-bash-tools/builds/<num> | jq

    ${0##*/} organizations/hari-sekhon/agents | jq

    ${0##*/} organizations/hari-sekhon/emojis | jq
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="/path [<curl_options>]"

if [ -z "${BUILDKITE_TOKEN:-}" ]; then
    usage "BUILDKITE_TOKEN environment variable is not set (generate this from the Web UI -> Personal Settings -> API Access Tokens (https://buildkite.com/user/api-access-tokens)"
fi

if [ $# -lt 1 ]; then
    usage "no /path given to query in the API"
fi

help_usage "$@"

min_args 1 "$@"

url_base="https://api.buildkite.com/v2"

url_path="$1"
shift || :

url_path="${url_path#$url_base}"
url_path="${url_path##/}"

export TOKEN="$BUILDKITE_TOKEN"

"$srcdir/curl_auth.sh" -sS --fail "$url_base/$url_path" "$@"
