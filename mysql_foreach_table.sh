#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-03-12 22:54:48 +0000 (Thu, 12 Mar 2020)
#
#  https://github.com/harisekhon/bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/harisekhon
#

# Run SQL query against all MySQL tables in all databases via mysql.sh
#
# Query can contain {db} and {table} placeholders which will be replaced for each table
#
# FILTER environment variable will restrict to matching fully qualified tables (<db>.<table>)
#
# Tested on MySQL 8.0.15

set -eu  # -o pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(dirname "$0")"

if [ $# -lt 1 ]; then
    echo "usage: ${0##*/} <query> [mysql_options]"
    exit 3
fi

query_template="$1"
shift

# exit the loop subshell if you Control-C
trap 'exit 130' INT

"$srcdir/mysql_list_tables.sh" "$@" |
while read -r db table; do
    printf '%s.%s\t' "$db" "$table"
    query="${query_template//\{db\}/\`$db\`}"
    query="${query//\{table\}/\`$table\`}"
    "$srcdir/mysql.sh" -s -D "$db" -e "$query" "$@"
done
