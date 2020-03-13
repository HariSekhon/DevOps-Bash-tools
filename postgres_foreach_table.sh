#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-03-12 16:50:46 +0000 (Thu, 12 Mar 2020)
#
#  https://github.com/harisekhon/bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/harisekhon
#

# Run SQL query against all PostgreSQL tables in all databases via psql.sh
#
# Query can contain {db}, {schema} and {table} placeholders which will be replaced for each table
#
# FILTER environment variable will restrict to matching fully qualified tables (<db>.<schema>.<table>)
#
# Tested on AWS RDS PostgreSQL 9.5.15

set -eu  # -o pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(dirname "$0")"

if [ $# -lt 1 ]; then
    echo "usage: ${0##*/} <query> [psql_options]"
    exit 3
fi

query_template="$1"
shift

# exit the loop subshell if you Control-C
trap 'exit 130' INT

AUTOFILTER=1 "$srcdir/postgres_list_tables.sh" "$@" |
while read -r db schema table; do
    printf '%s.%s.%s\t' "$db" "$schema" "$table"
    query="${query_template//\{db\}/\"$db\"}"
    query="${query//\{schema\}/\"$schema\"}"
    query="${query//\{table\}/\"$table\"}"
    # doing \c $db is noisy
    "$srcdir/psql.sh" -q -t -d "$db" -c "$query" "$@"
done
