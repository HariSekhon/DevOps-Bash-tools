#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#  args: echo "dataset_id =  \'{dataset_id}\'"
#
#  Author: Hari Sekhon
#  Date: 2020-09-16 08:54:54 +0100 (Wed, 16 Sep 2020)
#
#  https://github.com/harisekhon/bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/harisekhon
#

set -eu  # -o pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(dirname "${BASH_SOURCE[0]}")"

# shellcheck disable=SC1090
. "$srcdir/lib/utils.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Execute a command against all Google BigQuery dataset IDs in the current project

Command can contain {dataset_id} placeholder which will be replaced for each dataset

Requires GCloud SDK which must be configured and authorized for the project

Tested on Google BigQuery
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<command>"

help_usage "$@"

min_args 1 "$@"

command_template="$*"

# exit the loop subshell if you Control-C
trap 'exit 130' INT

"$srcdir/bigquery_list_datasets.sh" |
while read -r dataset_id; do
    printf '%s\t' "$dataset_id"
    command="${command_template//\{dataset_id\}/$dataset_id}"
    eval "$command"
done
