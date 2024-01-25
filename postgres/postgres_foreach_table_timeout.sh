#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-03-12 16:50:46 +0000 (Thu, 12 Mar 2020)
#
#  https://github.com/HariSekhon/DevOps-Bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/HariSekhon
#

set -eu  # -o pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck disable=SC1090,SC1091
. "$srcdir/lib/utils.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Run SQL query against all PostgreSQL tables in all databases via psql.sh

Query can contain {db}, {schema} and {table} placeholders which will be replaced for each table

FILTER environment variable will restrict to matching fully qualified tables (<db>.<schema>.<table>)

Auto-skips information_schema and pg_catalog schemas for safety

WARNING: do not run any command reading from standard input, otherwise it will consume the db/schema/table names and exit after the first iteration


Tested on AWS RDS PostgreSQL 9.5.15
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="\"<query>\" [<psql_options>]"

help_usage "$@"

min_args 1 "$@"

query_template="$1"
shift || :

# exit the loop subshell if you Control-C
trap 'exit 130' INT

timeout=""
if [ -n "${TABLE_TIMEOUT:-}" ]; then
    if ! [[ "$TABLE_TIMEOUT" =~ ^[[:digit:]]+$ ]]; then
        usage "invalid TABLE_TIMEOUT environment variable, must be an integer!"
    fi
    timeout="timeout -k 10 $TABLE_TIMEOUT"
fi

AUTOFILTER=1 "$srcdir/postgres_list_tables.sh" "$@" |
while read -r db schema table; do
    printf '%s.%s.%s\t' "$db" "$schema" "$table"
    query="${query_template//\{db\}/\"$db\"}"
    query="${query//\{schema\}/\"$schema\"}"
    query="${query//\{table\}/\"$table\"}"
    # weird situation on RDS PostgreSQL, hanging all night trying to select count(*) a table, happens on many tables
    set +e
    # time them out, skip them and carry on
    # doing \c $db is noisy, using -d $db instead
    $timeout "$srcdir/psql.sh" -q -t -d "$db" -c "$query" "$@"
    result=$?
    set -e
    if [ $result -ne 0 ]; then
        if [ $result -eq 124 ] &&
           [ -n "$timeout" ]; then
            echo
        else
            exit $result
        fi
    fi
done |
sed '/^[[:space:]]*$/d'
