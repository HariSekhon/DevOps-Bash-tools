#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2017-10-06 00:58:45 +0200 (Fri, 06 Oct 2017)
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
srcdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

. "$srcdir/docker.sh"

if is_inside_docker; then
    section "Docker Clean Checks"
    for x in \
        /root/.cache \
        /root/.cpan \
        /root/.cpanm \
        ~/.cache \
        ~/.cpan \
        ~/.cpanm \
        ; do
        if [ -e "$x" ]; then
            echo "$x detected, should have been removed from docker build"
            exit 1
        fi
    done
fi
