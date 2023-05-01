#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-03-12 20:22:28 +0000 (Thu, 12 Mar 2020)
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
Lists all MySQL tables using adjacent mysql.sh script

FILTER environment variable will restrict to matching tables (matches against fully qualified table name <db>.<table>)

AUTOFILTER if set to any value skips information_schema, performance_schema, sys and mysql databases

Tested on MySQL 8.0.15
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<mysql_options>]"

help_usage "$@"

"$srcdir/mysql.sh" -s -e "SELECT table_schema, TABLE_NAME FROM information_schema.tables;" "$@" |
sed 's/|//g; s/^[[:space:]]*//; s/[[:space:]]*$//; /^[[:space:]]*$/d' |
if [ -n "${AUTOFILTER:-}" ]; then
    grep -Ev '^(information_schema|performance_schema|sys|mysql)[[:space:]]'
else
    cat
fi |
while read -r db table; do
    if [ -n "${FILTER:-}" ] &&
       ! [[ "$db.$table" =~ $FILTER ]]; then
        continue
    fi
    printf '%s\t%s\n' "$db" "$table"
done
