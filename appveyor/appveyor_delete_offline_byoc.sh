#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-04-01 15:48:02 +0100 (Wed, 01 Apr 2020)
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

# eg. HariSekhon
if [ -z "${APPVEYOR_ACCOUNT:-}" ]; then
    echo "\$APPVEYOR_ACCOUNT not defined"
    exit 1
fi

echo "Querying AppVeyor for offline BYOC"
"$srcdir/appveyor_api.sh" "account/$APPVEYOR_ACCOUNT/build-clouds" |
jq -r '.[] | select(.status == "Offline") | [.name, .buildCloudId] | @tsv' |
while read -r name id; do
    echo "Deleting offline BYOC '$name'"
    # obtained from the Network debug tab of making UI calls
    "$srcdir/appveyor_api.sh" "account/$APPVEYOR_ACCOUNT/build-clouds/$id" -X DELETE
done
