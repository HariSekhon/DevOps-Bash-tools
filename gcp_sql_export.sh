#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-10-13 09:58:18 +0100 (Tue, 13 Oct 2020)
#
#  https://github.com/HariSekhon/bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/HariSekhon
#

# https://cloud.google.com/sql/docs/postgres/import-export/exporting
#
# https://cloud.google.com/sql/docs/postgres/import-export

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck disable=SC1090
. "$srcdir/lib/utils.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Exports all running non-replica SQL database instances in the current project to GCS

GCS bucket name must be specified

SQL instances can optionally be specified, otherwise iterates all running non-replica SQL instances
(only running instances can export, otherwise will error out)
(only non-replicas should be exported, replicas will likely fail due to conflict with replication recovery)

All databases for each SQL instance will be exported to the GCS bucket with file names in the format:

    <sql_instance>--<database_name>--backup-<date_timestamp>.sql.gz

Requirements:

- GCS bucket must already exist
- Each SQL instance's service account must have write permissions to the bucket (Storage Object Creator)
  - right now GCloud SDK doesn't support granting IAM permissions otherwise I'd have automated this too
  - get the list of service accounts for SQL instances to add to IAM from the adjacent script:

gcp_sql_service_accounts.sh

- Do not back up Replicas as it the export will likely conflict with the ongoing recovery operation like so:

ERROR: (gcloud.sql.export.sql) [ERROR_RDBMS] pg_dump: Dumping the contents of table \"<myTable>\" failed: PQgetResult() failed.
pg_dump: Error message from server: ERROR:  canceling statement due to conflict with recovery

"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<gcs_bucket> [<sql_instance1> <sql_instance2> ...]"

help_usage "$@"

min_args 1 "$@"

gcs_bucket="$1"
shift || :

sql_instances="${*}"

if [ -z "$sql_instances" ]; then
    # XXX: only running instances can do exports, otherwise will error out
    # XXX: only non-replicas back up correctly due to conflicts with ongoing replication recovery operations - see description above for details
    #sql_instances="$(gcloud sql instances list --format='get(name)' --filter 'STATUS=runnable' | grep -v -- '-replica$')"
    # better to not rely on the name having a '-replica' suffix and instead use the JSON instanceType field to exclude replicas
    sql_instances="$(gcloud sql instances list --format=json | jq -r '.[] | select(.instanceType != "READ_REPLICA_INSTANCE") | select(.state == "RUNNABLE") | .name')"
fi

timestamp "Exporting SQL instance(s) to GCS bucket '$gcs_bucket'"
for sql_instance in $sql_instances; do
    echo >&2
    timestamp "Getting list of databases for SQL instance '$sql_instance'"
    databases="$(gcloud sql databases list --instance="$sql_instance" --format='get(name)')"
    for database in $databases; do
        timestamp "Exporting SQL instance '$sql_instance' database '$database'"
        # adding .gz will auto-encrypt the bucket
        gcloud sql export sql "$sql_instance" "gs://$gcs_bucket/$sql_instance--$database--backup-$(date '+%F_%H%M').sql.gz" --database "$database"
    done
done
echo >&2
timestamp "Exports completed"
