#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-03-16 14:28:43 +0000 (Mon, 16 Mar 2020)
#
#  https://github.com/harisekhon/bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/harisekhon
#

# Exports Cloudera Navigator logs from the underlying PostgreSQL database to files in the local directory
#
# TSV Output format:
#
# <database>.<schema>.<table>     <row_count>
#
# FILTER environment variable will restrict to matching fully qualified tables (<db>.<schema>.<table>)
#
# Tested on AWS RDS PostgreSQL 9.5.15

# For individual table export timings set \timing in ~/.psqlrc

set -eu  # -o pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(dirname "$0")"

mkdir -pv cloudera_navigator_logs

echo "Exporting Cloudera Navigator logs from PostgreSQL database:"

# only export tables matching this regex
export FILTER='\.[[:alnum:]]+_audit_events_'

# doesn't seem to like \copy no matter how many backslashes
#"$srcdir/postgres_foreach_table.sh" "
#select replace('exporting {table}', '\"', '');
#\\copy (SELECT * FROM {db}.{schema}.{table}) TO replace('cloudera_navigator_logs/{db}.{schema}.{table}.csv', '\"', '') WITH (FORMAT CSV, HEADER);
#" "$@"

time {
"$srcdir/postgres_list_tables.sh" "$@" |
while read -r db schema table; do
    echo "SELECT 'Exporting $db.$schema.$table' AS progress;"
    echo "\\copy (SELECT * FROM \"$db\".\"$schema\".\"$table\") TO 'cloudera_navigator_logs/$db.$schema.$table.csv' WITH (FORMAT CSV, HEADER);"
done |
"$srcdir/psql.sh" "$@"
echo
echo "Cloudera Navigator PostgreSQL exports finished"
echo
}
