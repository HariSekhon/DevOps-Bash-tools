#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-01-23 11:51:09 +0000 (Thu, 23 Jan 2020)
#
#  https://github.com/HariSekhon/DevOps-Bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/HariSekhon
#

# Script to show recent Impala query metadata errors via Cloudera Manager API
#
# TSV output format:
#
# <time>    <database>      <user>      <query error>

# Tested on Cloudera Enterprise 5.10

# If encountering race conditions in metadata updates between Impalad daemons connected through a load balancer, you may be interested in setting
#
# SET SYNC_DDL=1;
#
# in your Impala session before issuing DDL statements or INSERTS into partitioned tables, see

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

"$srcdir/cloudera_manager_impala_queries.sh" |
jq -r '.queries[] |
       select(.attributes.query_status | test("metadata|No such file or directory"; "i")) |
       [.startTime, .database, .user, .attributes.query_status] |
       @tsv'
