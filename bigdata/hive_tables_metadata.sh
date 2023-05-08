#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2019-12-10 11:33:52 +0000 (Tue, 10 Dec 2019)
#
#  https://github.com/HariSekhon/DevOps-Bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/HariSekhon
#

# you will almost certainly have to comment out / remove '-o pipefail' to skip authorization errors such as that documented in impala_list_tables.sh
set -eu  # -o pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck disable=SC1090,SC1091
. "$srcdir/lib/utils.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Print each table's DDL metadata field eg. Location

Output Format:

<db>.<table>    <metadata_field>


FILTER environment variable will restrict to matching fully qualified tables (<db>.<table>)


Tested on Hive 1.1.0 on CDH 5.10, 5.16


For more documentation see the comments at the top of beeline.sh

For a better version written in Python see DevOps Python tools repo:

    https://github.com/HariSekhon/DevOps-Python-tools
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<metadata_field> [<beeline_options>]"

help_usage "$@"


field="$1"
shift || :

query_template="describe formatted {table}"

opts="--silent=true --outputformat=tsv2"

# exit the loop subshell if you Control-C
trap 'exit 130' INT

"$srcdir/hive_list_tables.sh" "$@" |
while read -r db table; do
    printf '%s.%s\t' "$db" "$table"
    query="${query_template//\{db\}/\`$db\`}"
    query="${query//\{table\}/\`$table\`}"
    # shellcheck disable=SC2086
    { "$srcdir/beeline.sh" $opts -e "USE \`$db\`; $query" "$@" || echo "ERROR running query: $query" >&2; } |
    {  grep "^$field" || echo UNKNOWN; } |
    sed "s/^$field:[[:space:]]*//; s/[[:space:]]*NULL[[:space:]]*$//"
done
