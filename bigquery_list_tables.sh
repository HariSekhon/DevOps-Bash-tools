#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#  args: bigquery-public-data.github_repos
#
#  Author: Hari Sekhon
#  Date: 2020-09-25 14:46:21 +0100 (Fri, 25 Sep 2020)
#
#  https://github.com/harisekhon/bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/harisekhon
#

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(dirname "${BASH_SOURCE[0]}")"

# shellcheck disable=SC1090
. "$srcdir/lib/utils.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Lists all BigQuery tables in a given dataset by querying BigQuery's Information Schema for that dataset

FILTER environment variable will restrict to matching tables (matches against fully qualified table name <dataset>.<schema>.<table>)

Limited to 10,000 table names by default (increase max_rows in script if you have a bigger dataset than this)

Tested on Google BigQuery
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<dataset>"

help_usage "$@"

min_args 1 "$@"

dataset="$1"

if ! [[ "$dataset" =~ ^[[:alnum:]_.-]+$ ]]; then
    die "invalid dataset name given (must contain only alphanumeric, dots, dashes and underscores):  $dataset"
fi

# XXX: you might need to edit this
max_rows=10000

set +e
output="$(bq query --quiet --headless --format=prettyjson --max_rows "$max_rows" --nouse_legacy_sql 'select table_catalog, table_schema, table_name FROM `'"$dataset"'.INFORMATION_SCHEMA.TABLES`;')"
if [ $? != 0 ]; then
    echo "$output" >&2
    exit 1
fi
jq -r '.[] | [.table_catalog, .table_schema, .table_name] | @tsv' <<< "$output" |
while read -r db schema table; do
    if [ -n "${FILTER:-}" ] &&
       ! [[ "$db.$schema.$table" =~ $FILTER ]]; then
        continue
    fi
    printf '%s\t%s\t%s\n' "$db" "$schema" "$table"
done
