#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-04-03 14:21:19 +0100 (Fri, 03 Apr 2020)
#
#  https://github.com/HariSekhon/DevOps-Bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/HariSekhon
#

# Gets last build status for a DockerHub repo
#
# eg.
#
# dockerhub_build_status.sh harisekhon/nagios-plugins | jq

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck disable=SC1090,SC1091
. "$srcdir/lib/utils.sh"

# shellcheck disable=SC2034
usage_description="Gets last build status for a DockerHub repo"

# shellcheck disable=SC2034
usage_args="<user/repo>"

if [ $# -lt 1 ]; then
    usage
fi

repo="$1"

curl -sSL "https://hub.docker.com/api/build/v1/source?image=$repo"
