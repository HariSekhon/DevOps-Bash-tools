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
# Tested on Hive 1.1.0 on CDH 5.10, 5.16
#
# For more documentation see the comments at the top of beeline.sh

# For a better version written in Python see DevOps Python tools repo:
#
# https://github.com/harisekhon/devops-python-tools

# you will almost certainly have to comment out / remove '-o pipefail' to skip authorization errors such as that documented in impala_list_tables.sh
set -eu  # -o pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(dirname "$0")"

usage(){
    echo "usage: ${0##*/} <metadata_field> [beeline_options]"
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

opts="--silent=true --outputformat=tsv2"

# exit the loop subshell if you Control-C
trap 'exit 130' INT

"$srcdir/hive_list_tables.sh" "$@" |
while read -r db table; do
    printf '%s.%s\t' "$db" "$table"
    query="${query_template//\{db\}/\`$db\`}"
    query="${query//\{table\}/\`$table\`}"
    # shellcheck disable=SC2086
    { "$srcdir/beeline.sh" $opts -e "USE \`$db\`; $query" "$@" || echo ERROR; } |
    {  grep "^$field" || echo UNKNOWN; } |
    sed "s/^$field:[[:space:]]*//; s/[[:space:]]*NULL[[:space:]]*$//"
done
