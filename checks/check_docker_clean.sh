#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2017-10-06 00:58:45 +0200 (Fri, 06 Oct 2017)
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

# shellcheck source=lib/docker.sh
. "$srcdir/lib/docker.sh"

if is_inside_docker; then
    "$srcdir/check_caches_clean.sh"
    if [ -n "$(find / -type f -name pytools_checks)" ]; then
        echo "pytools_checks detected, should have been removed from docker build"
        exit 1
    fi
fi
