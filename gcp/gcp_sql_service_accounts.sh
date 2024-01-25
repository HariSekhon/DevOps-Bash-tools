#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-10-13 09:58:18 +0100 (Tue, 13 Oct 2020)
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
Lists service accounts for each Cloud SQL instance in the current project

Use this list to copy in to IAM and grant Storage Object Creator on a bucket in order to run backup SQL Exports using the adjacent gcp_sql_export.sh script

Output Format:

<sql_instance_name>     <sql_instance_service_account>

SQL instances can be specified as arguments, otherwise lists service accounts for all SQL instances in the current project
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<sql_instance1> <sql_instance2> ...]"

help_usage "$@"

#min_args 1 "$@"

sql_instances="$*"

if [ -z "$sql_instances" ]; then
    sql_instances="$(gcloud sql instances list --format='get(name)')"
fi

for sql_instance in $sql_instances; do
    gcloud sql instances describe "$sql_instance" --format=json |
    jq -r '[.name, .serviceAccountEmailAddress] | @tsv'
done
