#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-01-02 16:19:20 +0000 (Thu, 02 Jan 2020)
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

# shellcheck source=lib/cloudera_manager.sh
. "$srcdir/lib/cloudera_manager.sh"

usage(){
    cat <<EOF
Script to Cloudera Manager API, auto-populating CM address, cluster name and authentication safely from environment

combine with jq commands to extract just the list of SQL queries from the rich json output

./cloudera_manager_api.sh /path

Tested on Cloudera Enterprise 5.10
EOF
    exit 3
}

if [ $# -lt 1 ]; then
    usage
fi

url_path="$1"
url_path="/${url_path##/}"

api_version="${CLOUDERA_API_VERSION:-7}"

"$srcdir/curl_auth.sh" -sS --connect-timeout 5 "$CLOUDERA_MANAGER/api/v${api_version}${url_path}"
echo
