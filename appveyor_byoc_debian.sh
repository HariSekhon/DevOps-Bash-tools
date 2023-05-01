#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-03-09 23:16:47 +0000 (Mon, 09 Mar 2020)
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
#. "$srcdir/lib/utils.sh"

cd "$srcdir"

if [ -z "${APPVEYOR_TOKEN:-}" ]; then
    echo "\$APPVEYOR_TOKEN not found in environment"
    exit 1
fi

export DEBIAN_FRONTEND=noninteractive

#exec docker run -ti --rm -e APPVEYOR_TOKEN -e DEBIAN_FRONTEND -v "$PWD":/pwd -w /pwd debian:9 ./appveyor_byoc.sh
#exec docker run -ti --rm -e APPVEYOR_TOKEN -e DEBIAN_FRONTEND -v "$PWD":/pwd -w /pwd harisekhon/appveyor:debian ./appveyor_byoc.sh
exec docker run -ti --rm -e APPVEYOR_TOKEN -e DEBIAN_FRONTEND harisekhon/appveyor:debian
