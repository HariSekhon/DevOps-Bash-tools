#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#  args: /nodes | jq .
#
#  Author: Hari Sekhon
#  Date: 2024-05-01 23:39:25 +0400 (Wed, 01 May 2024)
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
Queries the Rancher API

Automatically handles authentication via environment variables \$RANCHER_ACCESS_KEY and \$RANCHER_SECRET_KEY

Requires \$RANCHER_HOST and optionally \$RANCHER_PORT (default: 443) to be set

Can specify \$CURL_OPTS for options to pass to curl or provide them as arguments


Set up a personal access token here - may need to click 'Enable SSO' next to each token to access corporation organizations with SSO (eg. Azure AAD SSO):

    https://\$RANCHER_HOST:\$RANCHER_PORT/dashboard/account


API Reference:

    https://ranchermanager.docs.rancher.com/api/api-reference


Examples:

    List API endpoints

        ${0##*/} / | jq .

    List clusters:

        ${0##*/} /clusters | jq .

    List nodes:

        ${0##*/} /nodes | jq .

    List projects:

        ${0##*/} /projects | jq .

    List settings:

        ${0##*/} /settings | jq .

    List users:

        ${0##*/} /users | jq .

    List groups:

        ${0##*/} /groups | jq .
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="/path [<curl_options>]"

check_env_defined RANCHER_HOST
check_env_defined RANCHER_ACCESS_KEY
check_env_defined RANCHER_SECRET_KEY

url_base="https://$RANCHER_HOST:${RANCHER_PORT:-443}/v3"

help_usage "$@"

min_args 1 "$@"

curl_api_opts "$@"

url_path="$1"
shift || :

# false positive, this works
# shellcheck disable=SC2295
url_path="${url_path##$url_base}"
url_path="${url_path##/v3}"
url_path="${url_path##/}"

export USER="$RANCHER_ACCESS_KEY"
export PASSWORD="$RANCHER_SECRET_KEY"

"$srcdir/../bin/curl_auth.sh" "$url_base/$url_path" ${CURL_OPTS:+"${CURL_OPTS[@]}"} "$@" |
jq_debug_pipe_dump
