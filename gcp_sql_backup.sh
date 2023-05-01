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

# https://cloud.google.com/sql/docs/postgres/backup-recovery/backups
#
# https://cloud.google.com/sql/docs/postgres/backup-recovery/backing-up#gcloud

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck disable=SC1090,SC1091
. "$srcdir/lib/utils.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Run a manual backup of one or more Cloud SQL database instances in the current project

SQL instances can optionally be specified, otherwise iterates all running non-replica SQL instances

To enabled automated daily backups, run the adjacent script:

    gcp_sql_enable_automated_backups.sh

Cloud SQL backups are deleted with SQL instances so while these are convenient, you should also do full exports to GCS using the adjacent script:

    gcp_sql_export.sh
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<sql_instance1> <sql_instance2> ...]"

help_usage "$@"

no_more_opts "$@"

sql_instances="$*"

if [ -z "$sql_instances" ]; then
    # XXX: backups cannot be run for stopped instances or read replicas:
    # ERROR: (gcloud.sql.backups.create) HTTPError 400: This operation is not valid for this instance.
    # ERROR: (gcloud.sql.backups.create) HTTPError 400: Backups cannot be enabled for read replica instances.
    sql_instances="$(gcloud sql instances list --format=json |
                     jq -r '.[] | select(.instanceType != "READ_REPLICA_INSTANCE") | select(.state == "RUNNABLE") | .name')"
fi

for sql_instance in $sql_instances; do
    timestamp "Backing up SQL instance '$sql_instance':"
    gcloud sql backups create --instance="$sql_instance"  # --async
    echo >&2
done
timestamp "Cloud SQL Backups Completed"
