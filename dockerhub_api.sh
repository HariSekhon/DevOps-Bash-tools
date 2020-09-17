#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#  args: /repositories/harisekhon/hbase/tags | jq .
#
#  Author: Hari Sekhon
#  Date: 2020-09-14 15:25:12 +0100 (Mon, 14 Sep 2020)
#
#  https://github.com/harisekhon/bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/harisekhon
#

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(dirname "${BASH_SOURCE[0]}")"

# shellcheck disable=SC1090
. "$srcdir/lib/utils.sh"

# shellcheck disable=SC1090
. "$srcdir/lib/git.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Queries the DockerHub.com API v2

Automatically handles getting a JWT authentication token if you've got auth environment variables:
\$DOCKERHUB_USERNAME / \$DOCKERHUB_USER and \$DOCKERHUB_PASSWORD / \$DOCKERHUB_TOKEN

Can specify \$CURL_OPTS for options to pass to curl or provide them as arguments


Set up a personal access token here:

https://hub.docker.com/settings/security


API Reference:

https://docs.docker.com/registry/spec/api/


Examples:

# Get all the tags for a given repository called 'harisekhon/hbase':

${0##*/} /repositories/harisekhon/hbase/tags
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="/path [<curl_options>]"

#url_base="https://registry.hub.docker.com/v2"
url_base="https://hub.docker.com/v2"

CURL_OPTS="-sS --fail --connect-timeout 3 ${CURL_OPTS:-}"

help_usage "$@"

min_args 1 "$@"

user="${DOCKERHUB_USERNAME:-${DOCKERHUB_USER:-}}"
# curl_auth.sh does this automatically
#if [ -z "$user" ]; then
#    user="${USERNAME:${USER:-}}"
#fi

PASSWORD="${DOCKERHUB_PASSWORD:-${DOCKERHUB_TOKEN:-}}"

if [ -n "$user" ]; then
    export USERNAME="$user"
fi
export PASSWORD


url_path="$1"
shift || :

url_path="${url_path#https:\/\/registry.hub.docker.com\/v2}"
url_path="${url_path#https:\/\/hub.docker.com\/v2}"
url_path="${url_path##/}"

# need CURL_OPTS splitting, safer than eval
# shellcheck disable=SC2086
if [ -n "${PASSWORD:-}" ]; then
    # since DockerHub has many different API addresses it's easier to use JWT which isn't limited to a predefined service address
    JWT=1
    if [ -n "${JWT:-}" ]; then
        #output="$("$srcdir/curl_auth.sh" https://hub.docker.com/v2/users/login/ \
        output="$(curl https://hub.docker.com/v2/users/login/ \
                       $CURL_OPTS -X POST \
                       -H "Content-Type: application/json" \
                       -d '{"username": "'$user'", "password": "'$PASSWORD'"}'
        )"
        # JWT
        token="$(jq -r .token <<< "$output")"
        export JWT_TOKEN="$token"
    else
        # OAuth2
        output="$("$srcdir/curl_auth.sh" https://auth.docker.io/token -X GET \
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
    "$srcdir/curl_auth.sh" "$url_base/$url_path" "$@" $CURL_OPTS
else
    # proceed without authentication
    curl "$url_base/$url_path" "$@" $CURL_OPTS
fi
