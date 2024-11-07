#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#  args: /v1/validate
#
#  Author: Hari Sekhon
#  Date: 2022-03-03 12:23:03 +0000 (Thu, 03 Mar 2022)
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

# shellcheck disable=SC1090,SC1091
. "$srcdir/lib/git.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Queries the DataDog API

Requires \$DD_API_KEY / \$DATADOG_TOKEN to be set in the environment
If \$DD_APP_KEY is set, will also be sent in requests

Create an organization API key here:

    https://app.datadoghq.eu/organization-settings/api-keys

        (hint: copy the key, not the key id):

Create \$DD_APP_KEY here:

    https://app.datadoghq.eu/organization-settings/application-keys
        or
    https://app.datadoghq.eu/personal-settings/application-keys


If not using default US site, must also set \$DATADOG_HOST, eg:

    export DATADOG_HOST=https://api.datadoghq.eu

For site names, see:

    https://docs.datadoghq.com/api/latest/authentication/


Can specify \$CURL_OPTS for options to pass to curl or provide them as arguments


API Reference:

    https://docs.datadoghq.com/api/latest/


Defaults to /v2 API, but if /vN is specified, then uses that API instead, eg. prefixing /v1 to API endpoints that are only available in v1 such as /v1/validate or /v1/org


Examples:

# Validate your API token is working:

    ${0##*/} /v1/validate | jq .

# List users:

    ${0##*/} /users | jq .
        or
    ${0##*/} /v1/user | jq .


# List your organizations:

    ${0##*/} /v1/org | jq .

"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="/path [<curl_options>]"

url_base="${DATADOG_HOST:-https://api.datadoghq.com}/api/v2"

help_usage "$@"

min_args 1 "$@"

curl_api_opts "$@"

export TOKEN="${DD_API_KEY:-${DATADOG_TOKEN:-}}"
export CURL_AUTH_HEADER="DD-API-KEY:"

if [ -n "${DD_APP_KEY:-}" ]; then
    CURL_OPTS+=(-H "DD-APPLICATION-KEY: $DD_APP_KEY")
fi

url_path="$1"
shift || :

if [[ "$url_path" =~ ^/?v[[:digit:]]+/ ]]; then
    url_base="${url_base%%/v2}"
fi
url_path="${url_path//$url_base}"
url_path="${url_path##/}"

"$srcdir/../bin/curl_auth.sh" "$url_base/$url_path" "${CURL_OPTS[@]}" "$@"
