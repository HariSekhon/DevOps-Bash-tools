#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-11-28 22:33:44 +0000 (Sat, 28 Nov 2020)
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
Queries the GoCD API v6

\$GOCD_URL or \$GOCD_HOST must be set to point to the gocd server

If \$GOCD_HOST is used, then the following may also be set:

\$GOCD_PORT - defaults to 8111 and is only used if \$GOCD_URL is not used
\$GOCD_SSL  - defaults to http, any value enables https
\$GOCD_API_VERSION - defaults to v6

Sets Accept and Content-Type headers to application/json unless specified on the command line arguments.
Beware that Accept header also sets the \$GOCD_API_VERSION, so you'd have to do that yourself if overriding via command line args.

Important: Some API endpoints require older endpoints, such as /admin/config_repos which requires:

    -H 'Accept:application/vnd.go.cd.v3+json'


API Reference:

    https://api.gocd.org/current/


See Also:

    gocd.sh - boots a GoCD cluster in Docker and makes heavy use of this script against many API endpoints to configure it
                  convenient way of getting a GoCD API to test this script against, outputs the GOCD_URL and GOCD_TOKEN for you
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="/path [<curl_options>]"


help_usage "$@"

min_args 1 "$@"

url_path="$1"
shift || :

url_path="${url_path##/}"

# don't enforce as hard requirements here, instead try alternation further down and construct from what's available
#check_env_defined "GOCD_URL"
#check_env_defined "GOCD_HOST"
#check_env_defined "GOCD_TOKEN"

# not using curl_api_opts because need more control over the accept headers which control API version
CURL_OPTS=(-sS --fail --connect-timeout 3 "${CURL_OPTS[@]}")

if ! [[ "$*" =~ Accept: ]]; then
    if [ -n "${GOCD_API_VERSION:-}" ]; then
        GOCD_API_VERSION="${GOCD_API_VERSION#v}"
        if ! [[ "$GOCD_API_VERSION" =~ ^[[:digit:]]+$ ]]; then
            usage "invalid GOCD_API_VERSION defined in environment - must be an integer"
        fi
    else
        GOCD_API_VERSION=6
    fi
    CURL_OPTS+=(-H "Accept: application/vnd.go.cd.v${GOCD_API_VERSION}+json")
fi
if ! [[ "$*" =~ Content-Type: ]]; then
    CURL_OPTS+=(-H "Content-Type: application/json")
fi

if [ -n "${GOCD_URL:-}" ]; then
    url_base="${GOCD_URL%%/}"
else
    protocol="http"
    if [ -n "${GOCD_SSL:-}" ]; then
        protocol="https"
    fi
    [ -n "${GOCD_HOST:-}" ] || usage "neither \$GOCD_URL nor \$GOCD_HOST defined in environment"
    host="$GOCD_HOST"
    port="${GOCD_PORT:-8153}"
    url_base="$protocol://$host:$port"
fi

url_base+="/go/api"

if [ -n "${GOCD_TOKEN:-}" ]; then
    export TOKEN="$GOCD_TOKEN"
    "$srcdir/../bin/curl_auth.sh" "$url_base/$url_path" "${CURL_OPTS[@]}" "$@"
else
    curl "$url_base/$url_path" "${CURL_OPTS[@]}" "$@"
fi
