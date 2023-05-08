#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-09-30 11:21:54 +0100 (Wed, 30 Sep 2020)
#
#  https://github.com/HariSekhon/DevOps-Bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/HariSekhon
#

#  docker run -d -p 5000:5000 --restart always --name registry registry:2
#  docker tag centos localhost:5000/centos
#  docker tag ubuntu localhost:5000/ubuntu
#  docker tag registry:2 localhost:5000/registry:2
#  docker push localhost:5000/centos
#  docker push localhost:5000/ubuntu
#  docker push localhost:5000/registry:2
#
#  args: http://localhost:5000

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck disable=SC1090,SC1091
. "$srcdir/lib/utils.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Lists the images available in a private Docker Registry using the Docker Registry API v2

See adjacent docker_api.sh for authentication details
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="http(s)://host:port"

help_usage "$@"

min_args 1 "$@"

docker_registry_url="$1"
shift || :

if ! [[ "$docker_registry_url" =~ ^(https?://)?[[:alnum:].-]+:[[:digit:]]+/?$ ]]; then
    usage "invalid docker registry url: $docker_registry_url"
fi

if ! [[ "$docker_registry_url" =~ ^https?:// ]]; then
    docker_registry_url="http://$docker_registry_url"
fi

"$srcdir/docker_api.sh" "$docker_registry_url/v2/_catalog" |
jq -r '.repositories[]'
