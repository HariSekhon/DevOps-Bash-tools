#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#  args: /repositories/harisekhon/hbase/tags | jq .
#
#  Author: Hari Sekhon
#  Date: 2020-09-14 15:25:12 +0100 (Mon, 14 Sep 2020)
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
Queries the DockerHub.com API v2

Automatically handles getting an authentication token if you've got auth environment variables:

\$DOCKERHUB_USERNAME / \$DOCKERHUB_USER  / \$DOCKER_USERNAME / \$DOCKER_USER
\$DOCKERHUB_PASSWORD / \$DOCKERHUB_TOKEN / \$DOCKER_PASSWORD / \$DOCKER_TOKEN
\$DOCKERHUB_2FA_CODE (if set, does a 2nd level 2FA auth call with this code to get a token before calling the API endpoint)

Can specify \$CURL_OPTS for options to pass to curl or provide them as arguments


Set up a personal access token here:

    https://hub.docker.com/settings/security


API Reference:

    https://docs.docker.com/registry/spec/api/

DockerHub doesn't respect a lot of the Docker Registry API spec, eg. .../_catalog and .../tags/list both don't work and get 404s,
so may need to experiment more than with your own private docker registry


Examples:

# Get all the tags for a given repository called 'harisekhon/hbase':

    ${0##*/} /repositories/harisekhon/hbase/tags
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="/path [<curl_options>]"

#url_base="https://registry.hub.docker.com/v2"
url_base="https://hub.docker.com/v2"

help_usage "$@"

min_args 1 "$@"

curl_api_opts "$@"

user="${DOCKERHUB_USERNAME:-${DOCKERHUB_USER:-${DOCKER_USERNAME:-${DOCKER_USER:-}}}}"
PASSWORD="${DOCKERHUB_PASSWORD:-${DOCKERHUB_TOKEN:-${DOCKER_PASSWORD:-${DOCKER_TOKEN:-}}}}"

if [ -n "$user" ]; then
    export USERNAME="$user"
fi
export PASSWORD


url_path="$1"
shift || :

url_path="${url_path#https:\/\/registry.hub.docker.com}"
url_path="${url_path#https:\/\/hub.docker.com}"
# replace // with /
url_path="${url_path//\/\/\//\/}"
url_path="${url_path#/v2}"
url_path="${url_path##/}"

if [ -n "${PASSWORD:-}" ]; then
    # since DockerHub has many different API addresses it's easier to use JWT which isn't limited to a predefined service address
    JWT=1
    if [ -n "${JWT:-}" ]; then
        #output="$("$srcdir/../bin/curl_auth.sh" https://hub.docker.com/v2/users/login/ \
        output="$(curl https://hub.docker.com/v2/users/login/ \
                       -X POST \
                       "${CURL_OPTS[@]}" \
                       -d '{"username": "'"$user"'", "password": "'"$PASSWORD"'"}'
        )"
        token="$(jq -r .token <<< "$output")"
        if [ -n "${DOCKERHUB_2FA_CODE:-}" ]; then
            output="$(curl https://hub.docker.com/v2/users/2fa-login/ \
                           -X POST \
                           "${CURL_OPTS[@]}" \
                           -d '{"login_2fa_token": "'"$token"'", "code": "'"$DOCKERHUB_2FA_CODE"'"}'
            )"
            token="$(jq -r .token <<< "$output")"
        fi
        # automatically picked up by curl_auth.sh further down
        export JWT_TOKEN="$token"
    else
        # OAuth2
        output="$("$srcdir/../bin/curl_auth.sh" https://auth.docker.io/token -X GET \
                                         -H 'Content-Type: application/x-www-form-urlencoded' \
                                         -H 'Www-Authenticate: Bearer realm="https://auth.docker.io/token",service="hub.docker.com"' \
                                         -d "grant_type=password&access_type=online&client_id=${0##*}&service=hub.docker.com" # alternative: registry.docker.io
                                         #-d "grant_type=password&access_type=online&client_id=${0##*}&service=hub.docker.io&username=$user&password=$PASSWORD"
                                         #-H 'Www-Authenticate: Bearer realm="https://auth.docker.io/token",service="hub.docker.com",scope="repository:myuser/myimage:pull,push"'
        )"
        token="$(jq -r .access_token <<< "$output")"
        export TOKEN="$token"
    fi
    if [ -z "$token" ] || [ "$token" = null ]; then
        die "Authentication failed: $output"
    fi
    "$srcdir/../bin/curl_auth.sh" "$url_base/$url_path" "${CURL_OPTS[@]}" "$@"
else
    # proceed without authentication
    curl "$url_base/$url_path" "${CURL_OPTS[@]}" "$@"
fi
