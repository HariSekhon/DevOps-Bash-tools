#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-03-12 22:54:48 +0000 (Thu, 12 Mar 2020)
#
#  https://github.com/HariSekhon/DevOps-Bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/HariSekhon
#

set -eu  # o pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck disable=SC1090,SC1091
. "$srcdir/lib/utils.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Run SQL query against all MySQL tables in all databases via mysql.sh

Query can contain {db} and {table} placeholders which will be replaced for each table

FILTER environment variable will restrict to matching fully qualified tables (<db>.<table>)

Auto-skips information_schema, performance_schema, sys and mysql databases for safety

WARNING: do not run any command reading from standard input, otherwise it will consume the db/table names and exit after the first iteration


Tested on MySQL 8.0.15
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="\"<query>\" [<mysql_options>]"

help_usage "$@"

min_args 1 "$@"

query_template="$1"
shift || :

# exit the loop subshell if you Control-C
trap 'exit 130' INT

AUTOFILTER=1 "$srcdir/mysql_list_tables.sh" "$@" |
while read -r db table; do
    printf '%s.%s\t' "$db" "$table"
    query="${query_template//\{db\}/\`$db\`}"
    query="${query//\{table\}/\`$table\`}"
    "$srcdir/mysql.sh" -s -D "$db" -e "$query" "$@"
done
