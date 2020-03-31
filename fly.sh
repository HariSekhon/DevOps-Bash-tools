#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-03-21 18:24:59 +0000 (Sat, 21 Mar 2020)
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

target="${FLY_TARGET:-}"

opts=""
if [ -n "$target" ]; then
    opts="-t $target"
fi

# want word splitting
# shellcheck disable=SC2086
exec fly $opts "$@"
