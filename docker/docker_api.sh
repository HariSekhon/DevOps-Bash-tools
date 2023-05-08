#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#  args: https://hub.docker.com/v2/repositories/harisekhon/hbase/tags | jq .
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
Queries a Docker Registry API v2

Sends basic HTTP authentication if the following environment variables are defined:

\$DOCKER_USERNAME / \$DOCKER_USER
\$DOCKER_PASSWORD / \$DOCKER_TOKEN

Can specify \$CURL_OPTS for options to pass to curl or provide them as arguments


API Reference:

    https://docs.docker.com/registry/spec/api/


Examples:

# Get all the tags for a given repository called 'harisekhon/hbase' on DockerHub's public registry:

    ${0##*/} https://hub.docker.com/v2/repositories/harisekhon/hbase/tags


For authenticated queries against DockerHub which requires a more complicated OAuth or JWT workflow
rather than basic authentication, this script calls the adjacent 'dockerhub_api.sh' script
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="https://host:port/v2/... [<curl_options>]"

help_usage "$@"

min_args 1 "$@"

curl_api_opts "$@"

user="${DOCKER_USERNAME:-${DOCKER_USER:-}}"
PASSWORD="${DOCKER_PASSWORD:-${DOCKER_TOKEN:-}}"

if [ -n "$user" ]; then
    export USERNAME="$user"
fi
export PASSWORD

url="$1"
shift || :

if [[ "$url" =~ hub.docker.com ]]; then
    "$srcdir/dockerhub_api.sh" "$url" "$@"
elif [ -n "${PASSWORD:-}" ]; then
    "$srcdir/../bin/curl_auth.sh" "$url" "${CURL_OPTS[@]}" "$@"
else
    curl "$url" "${CURL_OPTS[@]}" "$@"
fi
