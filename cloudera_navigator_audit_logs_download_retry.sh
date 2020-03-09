#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-03-06 12:03:19 +0000 (Fri, 06 Mar 2020)
#
#  https://github.com/harisekhon/bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/harisekhon
#

# Cloudera Navigator fails to download some logs, so set it to loop retry the adjacent script cloudera_navigator_audit_logs_download.sh
#
# Tested on Cloudera Enterprise 5.10

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

time while true; do
    time "$srcdir/cloudera_navigator_audit_logs_download.sh" -k
    if find . -name 'navigator_audit_*.csv' -exec ls -l {} \; |
       awk '{print $5}' |
       grep -q '^0$'; then
        sleep 60
        continue
    fi
    echo FINISHED
    break
done
