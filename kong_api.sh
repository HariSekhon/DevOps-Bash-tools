#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#  args: /license/report | jq .
#
#  Author: Hari Sekhon
#  Date: 2023-04-07 23:36:30 +0100 (Fri, 07 Apr 2023)
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
Queries the Kong Gateway Admin API

See also the 'deck' command

Automatically handles authentication via environment variable \$KONG_TOKEN if available

KONG_API_HOST must be set
KONG_API_PORT defaults to 8433 for SSL
KONG_API_PROTOCOL defaults to 'https'

KONG_TOKEN (optional) if Admin API is secured with RBAC (Enterprise only)


Can specify \$CURL_OPTS for options to pass to curl or provide them as arguments


API Reference:

    https://docs.konghq.com/gateway/latest/admin-api/


Examples:

# Check health status:

    ${0##*/} /status | jq .


# List Admin API endpoints:

    ${0##*/} /endpoints | jq .


# List services:

    ${0##*/} /services | jq .


# Query a specific service:

    ${0##*/} /services/{service name or id} | jq .


# List routes:

    ${0##*/} /routes | jq .


# Query a specific service:

    ${0##*/} /routes/{route name or id} | jq .


# List consumers:

    ${0##*/} /consumers | jq .


# Install a plugin:

    ${0##*/} /plugins -X POST -d 'name=rate-limiting' | jq .


# List all plugins (only shows user installed plugins, not bundled ones it seems):

    ${0##*/} /plugins | jq .


# List enabled plugins including bundled ones:

    ${0##*/} /plugins/enabled | jq .


# List upstreams (backend services):

    ${0##*/} /upstreams | jq .


# Query one upstream

    ${0##*/} /upstreams/{upstream name or id} | jq .


# List all targets for an upstream backend service:

    ${0##*/} /upstreams/{name or id}/targets/all | jq .


# List workspaces:

    ${0##*/} /workspaces | jq .


# List RBAC users:

    ${0##*/} /rbac/users | jq .


# List admins:

    ${0##*/} /admins | jq .


# Get the current license details:

    ${0##*/} /license/report | jq .
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="/path [<curl_options>]"

check_env_defined KONG_API_HOST

host="$KONG_API_HOST"
port="${KONG_API_PORT:-8443}"
protocol="${KONG_API_PROTOCOL:-https}"
url_base="$protocol://$host:$port"

help_usage "$@"

min_args 1 "$@"

curl_api_opts "$@"

url_path="$1"
shift || :

url="$url_path"
if ! [[ "$url_path" =~ :// ]]; then
    url_path="${url_path##/}"
    url="$url_base/$url_path"
fi

export CURL_AUTH_HEADER="Kong-Admin-Token:"
export TOKEN="${KONG_TOKEN:-${TOKEN:-no_token_given}}"

"$srcdir/curl_auth.sh" "$url" ${CURL_OPTS:+"${CURL_OPTS[@]}"} "$@" |
jq_debug_pipe_dump
