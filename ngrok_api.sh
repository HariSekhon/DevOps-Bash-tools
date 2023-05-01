#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#  args: /api_keys | jq .
#
#  Author: Hari Sekhon
#  Date: 2022-06-11 09:03:03 +0100 (Sat, 11 Jun 2022)
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
Queries the NGrok.com API

Automatically handles authentication via environment variable \$NGROK_API_TOKEN

Can specify \$CURL_OPTS for options to pass to curl or provide them as arguments


Set up a personal access token here - may need to click 'Enable SSO' next to each token to access corporation organizations with SSO (eg. Azure AAD SSO):

    https://dashboard.ngrok.com/api


API Reference:

    https://ngrok.com/docs/api


Examples:

List API Keys:

    ${0##*/} /api_keys | jq .

List Agents:

    ${0##*/} /agent_ingresses | jq .

List Tunnels:

    ${0##*/} /tunnel_sessions | jq .

List FailOver Backends:

    ${0##*/} /backends/failover | jq .

List HTTP Response Backends:

    ${0##*/} /backends/http_response | jq .
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="/path [<curl_options>]"

url_base="https://api.ngrok.com"

help_usage "$@"

min_args 1 "$@"

curl_api_opts "$@"

check_env_defined "NGROK_API_TOKEN"

export TOKEN="${NGROK_API_TOKEN}"

url_path="${1:-}"
shift || :

url_path="${url_path//https:\/\/api.ngrok.com}"
url_path="${url_path##/}"

"$srcdir/curl_auth.sh" "$url_base/$url_path" -H "Ngrok-Version: 2" "${CURL_OPTS[@]}" "$@" |
jq_debug_pipe_dump
