#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-12-15 19:43:47 +0000 (Tue, 15 Dec 2020)
#
#  https://github.com/HariSekhon/bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/HariSekhon
#

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
libdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck disable=SC1090
. "$libdir/utils.sh"

buildkite_org(){
    # remember to set this eg. BUILDKITE_ORGANIZATION="hari-sekhon"
    local user_org="${BUILDKITE_ORGANIZATION:-${BUILDKITE_USER:-}}"

    if [ -z "$user_org" ]; then
        usage "\$BUILDKITE_ORGANIZATION / \$BUILDKITE_USER not defined in environment"
    fi
    echo "$user_org"
}
