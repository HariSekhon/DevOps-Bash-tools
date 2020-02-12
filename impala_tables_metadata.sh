#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2019-12-10 11:33:52 +0000 (Tue, 10 Dec 2019)
#
#  https://github.com/harisekhon/bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/harisekhon
#

# Print each table's DDL metadata field eg. Location
#
# FILTER environment variable will restrict to matching fully qualified tables (<db>.<table>)
#
# Caveats:
#
#     Hive is more reliable as Impala breaks on some table metadata definitions where Hive doesn't
#
#     Impala is faster than Hive for the first hundred or so tables but then slows down
#     so if you have a lot of tables I recommend you use the Hive version of this instead
#
# Tested on Impala 2.7.0, 2.12.0 on CDH 5.10, 5.16 with Kerberos and SSL
#
# For more documentation see the comments at the top of impala_shell.sh

# For a better version written in Python see DevOps Python tools repo:
#
# https://github.com/harisekhon/devops-python-tools

# you will almost certainly have to comment out / remove '-o pipefail' to skip authorization errors such as that documented in impala_list_tables.sh
set -eu  # -o pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(dirname "$0")"

usage(){
    echo "usage: ${0##*/} <metadata_field> [impala_shell_options]"
    exit 3
}

for arg; do
    if [[ "$arg" =~ -h|--help ]]; then
        usage
    fi
done

if [ $# -lt 1 ]; then
    usage
fi

field="$1"
shift

query_template="describe formatted {table}"

# exit the loop subshell if you Control-C
trap 'exit 130' INT

"$srcdir/impala_list_tables.sh" "$@" |
while read -r db table; do
    printf '%s.%s\t' "$db" "$table"
    query="${query_template//\{db\}/\`$db\`}"
    query="${query//\{table\}/\`$table\`}"
    { "$srcdir/impala_shell.sh" --quiet -Bq "USE \`$db\`; $query" "$@" || echo ERROR; } |
    {  grep "^$field" || echo UNKNOWN; } |
    sed "s/^$field:[[:space:]]*//; s/[[:space:]]*NULL[[:space:]]*$//"
done
