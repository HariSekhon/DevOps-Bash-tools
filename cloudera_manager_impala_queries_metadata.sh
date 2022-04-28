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

# Script to show recent Impala metadata refresh calls via Cloudera Manager API
#
# TSV output format:
#
# <time>    <database>  <user>      <statement>

# Tested on Cloudera Enterprise 5.10

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

"$srcdir/cloudera_manager_impala_queries.sh" |
jq -r '.queries[] |
       select(
            (.attributes.ddl_type == "RESET_METADATA")
            or
            (.attributes.query_status | test("metadata|No such file or directory"; "i"))
       ) |
       select(.statement | test("^(SELECT|INSERT|UPDATE|DELETE)"; "i") | not) |
       [.startTime, .database, .user, .statement] |
       @tsv'
