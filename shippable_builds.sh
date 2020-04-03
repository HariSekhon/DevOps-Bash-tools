#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-03-24 15:36:53 +0000 (Tue, 24 Mar 2020)
#
#  https://github.com/harisekhon/bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/harisekhon
#

# pending support ticket around permissions issue

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck disable=SC1090
. "$srcdir/lib/utils.sh"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_description="Returns recent Shippable build results"

if [ -z "${SHIPPABLE_ACCOUNT_ID:-}" ]; then
    usage "SHIPPABLE_ACCOUNT_ID environment variable is not set (get this value from your Web UI Dashboard)"
fi

for arg; do
    case "$arg" in
        -h|--help) usage
                   ;;
    esac
done

"$srcdir/shippable_api.sh" "/accounts/$SHIPPABLE_ACCOUNT_ID/runStatus" "$@"
#jq -r "$jq_query"
