#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#  args: echo "this is dataset_id {dataset_id}"
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

# Execute a command against all Google BigQuery dataset IDs in the current project
#
# Command can contain {dataset_id} placeholder which will be replaced for each dataset
#
# Requires GCloud SDK which must be configured and authorized for the project
#
# Tested on Google BigQuery

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(dirname "$0")"

if [ $# -lt 1 ]; then
    echo "usage: ${0##*/} <command>"
    exit 3
fi

command_template="$*"

# exit the loop subshell if you Control-C
trap 'exit 130' INT

"$srcdir/bigquery_list_datasets.sh" |
while read -r dataset_id; do
    printf '%s\t' "$dataset_id"
    command_template="${command_template//\{dataset_id\}/$dataset_id}"
    $command_template
done
