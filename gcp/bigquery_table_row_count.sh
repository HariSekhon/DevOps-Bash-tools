#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#  args: bigquery-public-data.github_repos.commits
#
#  Author: Hari Sekhon
#  Date: 2020-09-25 15:32:21 +0100 (Fri, 25 Sep 2020)
#
#  https://github.com/HariSekhon/DevOps-Bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/HariSekhon
#

set -eu  # -o pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck disable=SC1090,SC1091
. "$srcdir/lib/utils.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Counts rows for a given BigQuery table

Output:

<project>.<dataset>.<table>     <row_count>


Requires GCloud SDK which must be configured and authorized for the project

Tested on Google BigQuery
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<project>.]<dataset>.<table> <command>"

help_usage "$@"

min_args 1 "$@"

# validated in bigquery_list_tables.sh
table="$1"

# exit the loop subshell if you Control-C
trap 'exit 130' INT

output="$(bq query --quiet --headless --format=prettyjson --nouse_legacy_sql "SELECT COUNT(*) AS row_count FROM \`$table\`;")"
# shellcheck disable=SC2181
if [ $? != 0 ]; then
    echo "$output" >&2
    exit 1
fi
jq -r '.[].row_count' <<< "$output" |
while read -r row_count; do
    printf '%s\t%s\n' "$table" "$row_count"
done
