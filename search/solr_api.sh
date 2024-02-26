#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#  args: /api | jq .
#
#  Author: Hari Sekhon
#  Date: 2024-02-20 10:22:32 +0000 (Tue, 20 Feb 2024)
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
Works with the Solr API

Automatically handles authentication if environment variable \$SOLR_PASSWORD or \$SOLR_TOKEN are available

SOLR_HOST must be set
SOLR_PORT defaults to '8983'
SOLR_PROTOCOL defaults to 'http'

Can specify \$CURL_OPTS for options to pass to curl or provide them as arguments


API Reference:

    https://solr.apache.org/guide/solr/latest/configuration-guide/config-api.html

    https://solr.apache.org/guide/solr/latest/configuration-guide/request-parameters-api.html

    https://solr.apache.org/guide/solr/latest/configuration-guide/managed-resources.html

    https://solr.apache.org/guide/solr/latest/configuration-guide/collections-api.html

    https://solr.apache.org/guide/solr/latest/configuration-guide/configsets-api.html

    https://solr.apache.org/guide/solr/latest/configuration-guide/coreadmin-api.html

    https://solr.apache.org/guide/solr/latest/configuration-guide/v2-api.html


For convenience you may omit the /api prefix and it will be added automatically


Examples:

    ${0##*/} /solr/admin/collections?action=CLUSTERSTATUS

    ${0##*/} /solr/admin/collections?action=LIST

    ${0##*/} '/solr/admin/cores?action=LIST&distrib=false'

    Use this in scripts to abstract away the solr connection and authentication details via centralized environment variables such as a .envrc file

    ${0##*/} '/solr/admin/collections?action=CREATE&name=\$collection&numShards=\$NUM_SHARDS&maxShardsPerNode=\$MAX_SHARDS_PER_NODE&replicationFactor=3&wt=xml&collection.configName=\$collection&autoAddReplicas=true'

    See Collections API for more creating / modifying collections / splitting shards:

        https://solr.apache.org/guide/solr/latest/configuration-guide/collections-api.html


See Also

    Solr CLI - https://github.com/HariSekhon/DevOps-Perl-tools
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="/path [<curl_options>]"

check_env_defined SOLR_HOST

host="$SOLR_HOST"
port="${SOLR_PORT:-8983}"
protocol="${SOLR_PROTOCOL:-http}"
url_base="$protocol://$host:$port"

help_usage "$@"

min_args 1 "$@"

curl_api_opts "$@"

url_path="$1"
shift || :
url_path="${url_path#/}"
# might want to query /solr/admin or /api
#if ! [[ "$url_path" =~ ^api ]]; then
#    url_path="api/$url_path"
#fi

url="$url_path"
if ! [[ "$url_path" =~ :// ]]; then
    url_path="${url_path##/}"
    url="$url_base/$url_path"
fi

export USERNAME="${SOLR_USERNAME:-${SOLR_USER:-${USERNAME:-}}}"
export PASSWORD="${SOLR_PASSWORD:-}"
export TOKEN="${SOLR_TOKEN:-${TOKEN:-}}"

if not_blank "$PASSWORD" || not_blank "$TOKEN"; then
    "$srcdir/curl_auth.sh" "$url" ${CURL_OPTS:+"${CURL_OPTS[@]}"} "$@"
else
    # CURL_OPTS adds -H 'Accept: application/json' -H 'Content-Type: application/json' and other defaults from lib/utils.sh
    curl "$url" ${CURL_OPTS:+"${CURL_OPTS[@]}"}  "$@"
fi |
# XML shouldn't be returned due to above CURL_OPTS giving -H 'Accept: application/json'
jq_debug_pipe_dump
