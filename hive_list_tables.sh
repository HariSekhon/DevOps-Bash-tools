#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2019-12-06 11:10:26 +0000 (Fri, 06 Dec 2019)
#
#  https://github.com/HariSekhon/DevOps-Bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/HariSekhon
#

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck disable=SC1090,SC1091
. "$srcdir/lib/utils.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
List Hive tables in all databases via beeline

Output Format:

<database_name>     <table_name>


FILTER environment variable will restrict to matching fully qualified tables (<db>.<table>)


Tested on Hive 1.1.0 on CDH 5.10, 5.16


For Hive 3.0+ information schema is finally available which is more efficient than iterating per database eg.

SELECT * FROM information_schema.tables
(table_catalog, table_schema, table_name)

For Hive < 3.0 - consider using adjacent impala_list_tables.sh instead as it is much faster

For a better version written in Python see DevOps Python tools repo:

    https://github.com/HariSekhon/DevOps-Python-tools

Hive doesn't suffer from db authz issue listing metadata like Impala, which gets:

ERROR: AuthorizationException: User '<user>@<domain>' does not have privileges to access: default   Default Hive database.*.*
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<beeline_options>]"

help_usage "$@"


opts="--silent=true --outputformat=tsv2"

# shellcheck disable=SC2086
"$srcdir/hive_list_databases.sh" "$@" |
while read -r db; do
    "$srcdir/beeline.sh" $opts -e "SHOW TABLES FROM \`$db\`" "$@" |
    tail -n +2 |
    sed "s/^/$db	/"
done |
while read -r db table; do
    if [ -n "${FILTER:-}" ] &&
       ! [[ "$db.$table" =~ $FILTER ]]; then
        continue
    fi
    printf '%s\t%s\n' "$db" "$table"
done
