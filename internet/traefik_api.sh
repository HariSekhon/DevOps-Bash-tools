#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#  args: /api/version | jq .
#
#  Author: Hari Sekhon
#  Date: 2023-04-30 03:27:47 +0100 (Sun, 30 Apr 2023)
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
Queries the Traefik API

Automatically handles authentication via environment variable \$TRAEFIK_TOKEN if available

TRAEFIK_API_HOST must be set
TRAEFIK_API_PORT defaults to '443'
TRAEFIK_API_PROTOCOL defaults to 'https'

TRAEFIK_TOKEN (optional) if API is secured with a middleware JWT authentication token
If using HTTP basic auth set TRAEFIK_TOKEN=' ' with a blank and instead set USERNAME/PASSWORD environment variables, otherwise it'll use \$USERNAME from your shell and prompt for a password


Can specify \$CURL_OPTS for options to pass to curl or provide them as arguments


API Reference:

    https://doc.traefik.io/traefik/operations/api/


For convenience you may omit the /api prefix and it will be added automatically


Examples:

# Get the API version:

    ${0##*/} /api/version | jq .

# Overview stats of http, tcp, enabled features and providers:

    ${0##*/} /api/overview | jq .

# List entrypoints:

    ${0##*/} /api/entrypoints | jq .

# Get only the 'websecure' entrypoint:

    ${0##*/} /api/entrypoints/websecure | jq .

# List HTTP routers:

    ${0##*/} /api/http/routers | jq .

# List TCP routers:

    ${0##*/} /api/tcp/routers | jq .

# Get only the 'ping@internal' HTTP entrypoint:

    ${0##*/} /api/http/routers/ping@internal | jq .

# List HTTP middlewares:

    ${0##*/} /api/http/middlewares | jq .

# List TCP middlewares:

    ${0##*/} /api/tcp/middlewares | jq .

# Get only the 'traefik-strip-prefix-catch-all@kubernetescrd' HTTP middleware:

    ${0##*/} /api/http/middlewares/traefik-strip-prefix-catch-all@kubernetescrd | jq .

# List HTTP services:

    ${0##*/} /api/http/services | jq .

# List TCP services:

    ${0##*/} /api/tcp/services | jq .

# Get only the 'dashboard@internal' HTTP service:

    ${0##*/} /api/http/services/dashboard@internal | jq .
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="/path [<curl_options>]"

check_env_defined TRAEFIK_API_HOST

host="$TRAEFIK_API_HOST"
port="${TRAEFIK_API_PORT:-443}"
protocol="${TRAEFIK_API_PROTOCOL:-https}"
url_base="$protocol://$host:$port"

help_usage "$@"

min_args 1 "$@"

curl_api_opts "$@"

url_path="$1"
shift || :
url_path="${url_path#/}"
if ! [[ "$url_path" =~ ^api ]]; then
    url_path="api/$url_path"
fi

url="$url_path"
if ! [[ "$url_path" =~ :// ]]; then
    url_path="${url_path##/}"
    url="$url_base/$url_path"
fi

export TOKEN="${TRAEFIK_TOKEN:-${TOKEN:-no_token_given}}"

"$srcdir/../bin/curl_auth.sh" "$url" ${CURL_OPTS:+"${CURL_OPTS[@]}"} "$@" |
jq_debug_pipe_dump
