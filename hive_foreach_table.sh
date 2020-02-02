#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2019-12-06 11:10:26 +0000 (Fri, 06 Dec 2019)
#
#  https://github.com/harisekhon/bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/harisekhon
#

# Run SQL query against all Hive tables in all databases via beeline
#
# Query can contain {db} and {table} placeholders which will be replaced for each table
#
#
# Tested on Hive 1.1.0 on CDH 5.10, 5.16

# For a better version written in Python see DevOps Python tools repo:
#
# https://github.com/harisekhon/devops-python-tools

# you will need to comment out / remove '-o pipefail' below to skip errors if you aren't authorized to use
# any of the databases to avoid the script exiting early upon encountering any authorization error such:
#
# ERROR: AuthorizationException: User '<user>@<domain>' does not have privileges to access: default   Default Hive database.*.*
#
set -eu -o pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(dirname "$0")"

if [ $# -lt 1 ]; then
    echo "usage: ${0##*/} <query> [beeline_options]"
    exit 3
fi

query_template="$1"
shift

opts="--silent=true --outputformat=tsv2"

# exit the loop subshell if you Control-C
trap 'exit 130' INT

# shellcheck disable=SC2086
"$srcdir/hive_list_tables.sh" "$@" |
while read -r db table; do
    printf '%s.%s\t' "$db" "$table"
    query="${query_template//\{db\}/\`$db\`}"
    query="${query//\{table\}/\`$table\`}"
    "$srcdir/beeline.sh" $opts -e "USE \`$db\`; $query" "$@" |
    tail -n +2
done
