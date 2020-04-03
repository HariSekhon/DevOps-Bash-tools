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

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck disable=SC1090
. "$srcdir/lib/utils.sh"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_description="Queries the Shippable API, auto-populating the base and API tokens from the environment"
# shellcheck disable=SC2034
usage_args="/path [<curl_options>]"

if [ -z "${SHIPPABLE_TOKEN:-}" ]; then
    usage "SHIPPABLE_TOKEN environment variable is not set (generate this from your Web UI Dashboard -> profile -> API AUTH TOKENS"
fi

if [ $# -lt 1 ]; then
    usage "no /path given to query in the API"
fi

for arg; do
    case "$arg" in
        -h|--help) usage
                   ;;
   esac
done

url_path="${1##/}"
shift || :

if is_curl_min_version 7.55; then
    # hide token from process list if curl is new enough to support this trick
    curl -sSH 'Accept: application/json' -H @<(cat <<< "Authorization: apiToken $SHIPPABLE_TOKEN") "https://api.shippable.com/$url_path" "$@"
else
    curl -sSH 'Accept: application/json' -H "Authorization: apiToken $SHIPPABLE_TOKEN" "https://api.shippable.com/$url_path" "$@"
fi
