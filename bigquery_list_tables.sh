#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#  args: bigquery-public-data.github_repos
#
#  Author: Hari Sekhon
#  Date: 2020-09-25 14:46:21 +0100 (Fri, 25 Sep 2020)
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
Lists all BigQuery tables in a given dataset by querying BigQuery's Information Schema for that dataset

To list tables from a dataset in another project, just prefix the project eg. <project>.<dataset>

Output Format:

<project>   <dataset>   <table>

FILTER environment variable will restrict to matching tables (matches against fully qualified table name <project>.<dataset>.<table>)

Limited to 10,000 table names by default (increase max_rows in script if you have a bigger dataset than this)

Tested on Google BigQuery
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<project>.]<dataset>"

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
# shellcheck disable=SC2181
if [ $? != 0 ]; then
    echo "$output" >&2
    exit 1
fi
set -e
jq -r '.[] | [.table_catalog, .table_schema, .table_name] | @tsv' <<< "$output" |
while read -r project dataset table; do
    if [ -n "${FILTER:-}" ] &&
       ! [[ "$project.$dataset.$table" =~ $FILTER ]]; then
        continue
    fi
    printf '%s\t%s\t%s\n' "$project" "$dataset" "$table"
done
