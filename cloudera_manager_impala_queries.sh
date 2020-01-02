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

#

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ -z "${CLOUDERA_MANAGER:-}" ]; then
    read -r -p 'Enter Clouder Manager host URL: ' CLOUDERA_MANAGER
fi

if [ -n "${CLOUDERA_MANAGER_SSL:-}" ]; then
    CLOUDERA_MANAGER="https://${CLOUDERA_MANAGER#*://}"
fi

# seems to work on CM / CDH 5.10.0 even when cluster is set to 'blah' but probably shouldn't rely on that
if [ -z "${CLOUDERA_CLUSTER:-}" ]; then
    read -r -p 'Enter Clouder Manager Cluster name: ' CLOUDERA_CLUSTER
fi

# 2020-01-02T16%3A17%3A57.514Z
# url encoding : => %3A seems to be done automatically by curl so not bothering to urlencode here
now_timestamp="$(date '+%Y-%m-%dT%H:%M:%S.000Z')"

echo "fetching queryies up to now:  $now_timestamp" >&2

"$srcdir/curl_auth.sh" "$CLOUDERA_MANAGER/api/v7/clusters/$CLOUDERA_CLUSTER/services/impala/impalaQueries?from=1970-01-01T00%3A00%3A00.000Z&to=$now_timestamp&filter="
