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

# Get row counts for all Hive tables in all databases via beeline
#
# TSV Output format:
#
# <database>    <table>     <row_count>
#
# Tested on Hive 1.1.0 on CDH 5.10, 5.16

# you will need to comment out / remove '-o pipefail' below to skip errors if you aren't authorized to use
# any of the databases to avoid the script exiting early upon encountering any authorization error such:
#
# ERROR: AuthorizationException: User '<user>@<domain>' does not have privileges to access: default   Default Hive database.*.*
#
set -eu -o pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(dirname "$0")"

opts="--silent=true --outputformat=tsv2"

# shellcheck disable=SC2086
"$srcdir/hive_list_tables.sh" |
while read -r db table; do
    printf '%s\t%s\t' "$db" "$table"
    "$srcdir/beeline.sh" $opts -e "SELECT COUNT(*) FROM \`$db\`.\`$table\`" "$@" |
    tail -n +2
done
