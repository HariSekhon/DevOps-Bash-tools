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
# FILTER environment variable will restrict to matching fully qualified tables (<db>.<schema>.<table>)
#
# CSV Output Format is dependent on database columns and can change, but at time of writing was:
#
# HDFS logs:
#
# id,service_name,username,ip_addr,event_time,operation,src,dest,permissions,allowed,impersonator,delegation_token_id
#
# Tested on AWS RDS PostgreSQL 9.5.15

# For individual table export timings set \timing in ~/.psqlrc

set -eu  # -o pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(dirname "$0")"

# shellcheck disable=SC1090
. "$srcdir/lib/utils.sh"

logdir="$PWD/cloudera_navigator_logs"

# only export tables matching this regex
export FILTER='\.[[:alnum:]]+_audit_events_'

# if you only want Hive + Impala logs to determine table access patterns
#export FILTER='\.(hive|impala)_audit_events_'

tstamp "Exporting Cloudera Navigator logs from PostgreSQL database:"
echo >&2

# doesn't seem to like \copy no matter how many backslashes
#"$srcdir/postgres_foreach_table.sh" "
#select replace('exporting {table}', '\"', '');
#\\copy (SELECT * FROM {db}.{schema}.{table}) TO replace('cloudera_navigator_logs/{db}.{schema}.{table}.csv', '\"', '') WITH (FORMAT CSV, HEADER);
#" "$@"

tstamp "logdir = $logdir"
echo >&2
mkdir -pv "$logdir"

time {
"$srcdir/postgres_list_tables.sh" "$@" |
while read -r db schema table; do
#    echo "SELECT 'Exporting $db.$schema.$table' AS progress;"
#    echo "\\copy (SELECT * FROM \"$db\".\"$schema\".\"$table\") TO 'cloudera_navigator_logs/$db.$schema.$table.csv' WITH (FORMAT CSV, HEADER);"
#done |
#"$srcdir/psql.sh" "$@"
    filename="$logdir/$db.$schema.$table.csv"
    tstamp "Exporting $db.$schema.$table:  "
    rm -fv "$filename"  # would get overwritten anyway but removing to detect when psql errors out without non-zero exit code
    psql.sh -c "\\copy (SELECT * FROM \"$db\".\"$schema\".\"$table\") TO '$filename' WITH (FORMAT CSV, HEADER);"
    if ! [ -f "$filename" ]; then
        tstamp "ERROR: EXPORT FAILED"
        exit 1
    fi
    # empty
    if ! [ -s "$filename" ]; then
        tstamp "${filename##*/} is empty, removing..."
        rm -f "$filename"
        echo >&2
        continue
    fi
    # only a header line
    if wc -l "$filename" | grep -q '^1[[:space:]]'; then
        tstamp "${filename##*/} has only header line, removing..."
        rm -f "$filename"
        echo >&2
        continue
    fi
    # we run out of space without this as logs can easily be dozens of GB per day per service
    tstamp "compressing $filename"
    # don't background if short on space as big new log will fill faster than old log can be gzipped and is only removed after gzip completes
    # --force overwrite of existing gzip logs
    gzip -9 --force "$filename" &
    echo >&2
done || exit $?
tstamp "waiting for background log compression to finish..."
wait
echo >&2
tstamp "Cloudera Navigator PostgreSQL exports finished"
echo >&2
}
