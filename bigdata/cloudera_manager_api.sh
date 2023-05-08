#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-01-02 16:19:20 +0000 (Thu, 02 Jan 2020)
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

# shellcheck source=lib/cloudera_manager.sh
. "$srcdir/lib/cloudera_manager.sh"

usage(){
    cat <<EOF
Script to query Cloudera Manager API, auto-populating Cloudera Manager host address, cluster name from environment and
safely passing credentials via a file descriptor to avoid exposing them in the process list as arguments or OS logging
history

Arguments are passed through to curl (eg. -k to not verify internal self-signed SSL certificate)

Combine with jq commands to extract the info you want

Environment variables (prompts for address, cluster and password if not passed via environment variables):

\$CLOUDERA_MANAGER_HOST / \$CLOUDERA_MANAGER
\$CLOUDERA_MANAGER_CLUSTER / \$CLOUDERA_CLUSTER
\$CLOUDERA_MANAGER_SSL (any value enables SSL and changes default port from 7180 to 7183)
\$CLOUDERA_MANAGER_USER / \$CLOUDERA_USER / \$USER
\$CLOUDERA_MANAGER_PASSWORD / \$CLOUDERA_PASSWORD / \$USER

./cloudera_manager_api.sh /path

Used by various adjacent cloudera_manager_*.sh scripts

Tested on Cloudera Enterprise 5.10
EOF
    exit 3
}

if [ $# -lt 1 ]; then
    usage
fi

for arg; do
    case "$arg" in
        -h|--help)  usage
                    ;;
    esac
done

url_path="$1"
url_path="/${url_path##/}"

# remove $1 so we can pass remaining args to curl_auth.sh
shift || :

# https://docs.cloudera.com/documentation/enterprise/6/6.3/topics/cn_navigator_api_overview.html#api-version-compatility
api_version="${CLOUDERA_API_VERSION:-7}"

"$srcdir/../bin/curl_auth.sh" "$CLOUDERA_MANAGER/api/v${api_version}${url_path}" -sS --fail --connect-timeout 5 "$@"
