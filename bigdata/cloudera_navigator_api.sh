#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-03-04 09:56:42 +0000 (Wed, 04 Mar 2020)
#
#  https://github.com/HariSekhon/DevOps-Bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/HariSekhon
#

# https://docs.cloudera.com/documentation/enterprise/5-10-x/topics/navigator_data_mgmt.html#xd_583c10bfdbd326ba-7dae4aa6-147c30d0933--7b44

# https://docs.cloudera.com/documentation/enterprise/6/6.3/topics/data_mgmt_audit_reports.html

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=lib/cloudera_navigator.sh
. "$srcdir/lib/cloudera_navigator.sh"

usage(){
    cat <<EOF
Script to query Cloudera Navigator API, auto-populating Cloudera Navigator host address, cluster name from environment and
safely passing credentials via a file descriptor to avoid exposing them in the process list as arguments or OS logging
history

Arguments are passed through to curl (eg. -k to not verify internal self-signed SSL certificate)

Combine with jq commands to extract the info you want

Environment variables (prompts for address and password if not passed via environment variables):

\$CLOUDERA_NAVIGATOR_HOST / \$CLOUDERA_NAVIGATOR
\$CLOUDERA_NAVIGATOR_SSL (any value enables SSL and changes default port from 7186 to 7187)
\$CLOUDERA_NAVIGATOR_USER / \$CLOUDERA_USER / \$USER
\$CLOUDERA_NAVIGATOR_PASSWORD / \$CLOUDERA_PASSWORD / \$USER

    ./cloudera_navigator_api.sh /path

Used by various adjacent cloudera_navigator_*.sh scripts

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

api_version="${CLOUDERA_API_VERSION:-10}"

"$srcdir/../bin/curl_auth.sh" "$CLOUDERA_NAVIGATOR/api/v${api_version}${url_path}" -sS --fail --connect-timeout 5 "$@"
