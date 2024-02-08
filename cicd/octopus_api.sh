#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2022-08-02 19:20:38 +0100 (Tue, 02 Aug 2022)
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
Queries the Octopus Deploy API

Requires the following environment variables to be set:

    \$OCTOPUS_URL / \$OCTOPUS_CLI_SERVER - including the http scheme eg. http://localhost:8080
    \$OCTOPUS_TOKEN / \$OCTOPUS_CLI_API_KEY - your personal API key generated in your profile


Generate your API key at Profile -> My API Keys, eg:

    http://localhost:8080/app#/Spaces-1/users/me/apiKeys


API Swagger Reference can be found at \$OCTOPUS_URL/swaggerui, eg:

    http://localhost:8080/swaggerui/index.html


API Documentation:

    https://octopus.com/docs/octopus-rest-api


Examples:

    # list the other endpoints
    ${0##*/} /

    ${0##*/} /authentication
    ${0##*/} /configuration
    ${0##*/} /dashboard
    ${0##*/} /dashboardconfiguration
    ${0##*/} /machines
    ${0##*/} /featuresConfiguration
    ${0##*/} /licenses/licenses-current
    ${0##*/} /packages
    ${0##*/} /projects
    ${0##*/} /tasks
    ${0##*/} /workers


See Also:

    install/install_octo.sh - Installs the Octopus Deploy CLI
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="/path [<curl_options>]"

OCTOPUS_URL="${OCTOPUS_URL:-${OCTOPUS_CLI_SERVER:-}}"
OCTOPUS_TOKEN="${OCTOPUS_TOKEN:-${OCTOPUS_CLI_API_KEY:-}}"

check_env_defined "OCTOPUS_URL"
check_env_defined "OCTOPUS_TOKEN"

help_usage "$@"

min_args 1 "$@"

curl_api_opts "$@"

url_path="$1"
shift || :

export TOKEN="$OCTOPUS_TOKEN"
export CURL_AUTH_HEADER="X-Octopus-ApiKey:"

url_base="$OCTOPUS_URL/api"

"$srcdir/../bin/curl_auth.sh" "$url_base/$url_path" ${CURL_OPTS:+"${CURL_OPTS[@]}"} "$@" |
jq_debug_pipe_dump
