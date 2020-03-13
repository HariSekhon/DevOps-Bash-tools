#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-03-13 11:05:05 +0000 (Fri, 13 Mar 2020)
#
#  https://github.com/harisekhon/bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/harisekhon
#

# Counts rows for all MySQL tables in all databases using adjacent mysql.sh script
#
# TSV Output format:
#
# <database>.<table>     <row_count>
#
# FILTER environment variable will restrict to matching fully qualified tables (<db>.<table>)
#
# Tested on MySQL 8.0.15

set -eu  # -o pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(dirname "$0")"

exec "$srcdir/mysql_foreach_table.sh" "SELECT COUNT(*) FROM {db}.{table}" "$@"
