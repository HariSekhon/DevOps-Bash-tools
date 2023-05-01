#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#  args: /account | jq .
#
#  Author: Hari Sekhon
#  Date: 2022-07-06 00:22:15 +0100 (Wed, 06 Jul 2022)
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
Queries the Digital Ocean API

Automatically handles authentication via environment variables \$DIGITALOCEAN_ACCESS_TOKEN, \$DIGITALOCEAN_TOKEN or \$DIGITAL_OCEAN_TOKEN in that order of priority

Can specify \$CURL_OPTS for options to pass to curl or provide them as arguments


Generate a personal access token here:

    https://cloud.digitalocean.com/account/api/tokens


API Reference:

    https://docs.digitalocean.com/reference/api/


Defaults to /v2 API, but if /vN is specified, then uses that API instead, eg. prefixing /v1 to API endpoints that are only available in /v1 or if a new /v3 API gets released


Examples:

    # Get your account details:

        ${0##*/} /account | jq .

    # Get your account balance:

        ${0##*/} /customers/my/balance | jq .

    # List the projects in your account:

        ${0##*/} /projects | jq .

    # List the SSH keys in your account:

        ${0##*/} /account/keys | jq .

    # List the actions taken on your account:

        ${0##*/} /actions | jq .

    # List all Regions - datacentres, features, and machine sizes:

        ${0##*/} /regions | jq .

    # List your Kubernetes clusters:

        ${0##*/} /kubernetes/clusters | jq .

    # List the load balancers in your account:

        ${0##*/} /load_balancers | jq .

    # List all block storage volumes:

        ${0##*/} /volumes | jq .

    # List all droplets:

        ${0##*/} /droplets | jq .
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="/path [<curl_options>]"

url_base="https://api.digitalocean.com/v2"

help_usage "$@"

min_args 1 "$@"

curl_api_opts "$@"

DIGITALOCEAN_ACCESS_TOKEN="${DIGITALOCEAN_ACCESS_TOKEN:-${DIGITALOCEAN_TOKEN:-${DIGITAL_OCEAN_TOKEN:-}}}"

check_env_defined DIGITALOCEAN_ACCESS_TOKEN

export TOKEN="${DIGITALOCEAN_ACCESS_TOKEN:-}"

url_path="${1:-}"
shift || :

if [[ "$url_path" =~ ^/?v[[:digit:]]+/ ]]; then
    url_base="${url_base%%/v2}"
fi
url_path="${url_path//$url_base}"
url_path="${url_path##/}"

"$srcdir/curl_auth.sh" "$url_base/$url_path" "${CURL_OPTS[@]}" "$@" |
jq_debug_pipe_dump
