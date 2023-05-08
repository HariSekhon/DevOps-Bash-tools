#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#  args: bigquery-public-data.github_repos echo "project = {project}, dataset = {dataset} / schema = {schema}, table = {table}"
#
#  Author: Hari Sekhon
#  Date: 2020-09-16 08:54:54 +0100 (Wed, 16 Sep 2020)
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
Execute a command against all Google BigQuery tables in a given dataset in the current project

Command can contain {project}, {dataset} / {schema} and {table} placeholders which will be replaced for each table

WARNING: do not run any command reading from standard input, otherwise it will consume the project/dataset/table names and exit after the first iteration

Requires GCloud SDK which must be configured and authorized for the project

Tested on Google BigQuery
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<project>.]<dataset> <command>"

help_usage "$@"

min_args 2 "$@"

# validated in bigquery_list_tables.sh
dataset="$1"
shift || :

command_template="$*"

# exit the loop subshell if you Control-C
trap 'exit 130' INT

"$srcdir/bigquery_list_tables.sh" "$dataset" |
while read -r project dataset table; do
    if [ -z "${NO_HEADING:-}" ]; then
        hr
        echo "Project = $project, Dataset/Schema = $dataset, Table = $table"
        hr
    fi >&2
    command="${command_template//\{project\}/$project}"
    command="${command//\{dataset\}/$dataset}"
    command="${command//\{schema\}/$dataset}"
    command="${command//\{table\}/$table}"
    eval "$command"
    if [ -z "${NO_HEADING:-}" ]; then
        echo
    fi >&2
done
