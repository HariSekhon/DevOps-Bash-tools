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

# https://cloud.google.com/sql/docs/postgres/import-export/exporting
#
# https://cloud.google.com/sql/docs/postgres/import-export

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck disable=SC1090,SC1091
. "$srcdir/lib/utils.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Exports all running non-replica SQL database instances in the current project to GCS

GCS bucket name must be specified

SQL instances can optionally be specified, otherwise iterates all running non-replica SQL instances
(only running instances can export, otherwise will error out)
(only non-replicas should be exported, replicas will likely fail due to conflict with replication recovery)

All databases for each SQL instance will be exported to the GCS bucket with file names in the format:

    gs://<bucket>/backups/sql/<sql_instance>--<database_name>--<date_timestamp>.sql.gz

Requirements:

- GCS bucket must already exist
- Each SQL instance's service account will be granted the minimal role Storage Object Creator to the specified bucket to allow the export to succeed


- Do not back up Replicas as it the export will likely conflict with the ongoing recovery operation like so:

    ERROR: (gcloud.sql.export.sql) [ERROR_RDBMS] pg_dump: Dumping the contents of table \"<myTable>\" failed: PQgetResult() failed.
    pg_dump: Error message from server: ERROR:  canceling statement due to conflict with recovery


For busy heavily utilized production databases this may put a strain on their resources or take a long time due to contention leading to the export command erroring out with a timeout waiting like so:

    Exporting Cloud SQL instance...failed.
    ERROR: (gcloud.sql.export.sql) Operation https://sqladmin.googleapis.com/sql/v1beta4/projects/<project>/operations/<instance_id> is taking longer than expected. You can continue waiting for the operation by running \`gcloud beta sql operations wait --project <project> <instance_id>\`


In this case your options are modify the export command to use --async or use the --offload flag to use serverless export (will take 5 minutes longer to spin up a replica and additional charges will apply)
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<gcs_bucket> [<sql_instance1> <sql_instance2> ...]"

help_usage "$@"

no_more_opts "$@"

min_args 1 "$@"

gcs_bucket="$1"
shift || :

sql_instances="$*"

if [ -z "$sql_instances" ]; then
    sql_instances="$("$srcdir/gcp_sql_running_primaries.sh")"
fi

timestamp "Granting SQL instance(s) objectCreator on GCS bucket '$gcs_bucket'"
# want splitting
# shellcheck disable=SC2086
"$srcdir/gcp_sql_grant_instances_gcs_object_creator.sh" "$gcs_bucket" $sql_instances
echo >&2

timestamp "Exporting SQL instance(s) to GCS bucket '$gcs_bucket'"
for sql_instance in $sql_instances; do
    echo >&2
    timestamp "Getting list of databases for SQL instance '$sql_instance'"
    databases="$(gcloud sql databases list --instance="$sql_instance" --format='get(name)')"
    for database in $databases; do
        # skip information schema, not allowed to dump this on MySQL, fails with:
        # ERROR: (gcloud.sql.export.sql) [ERROR_RDBMS] mysqldump: Dumping 'information_schema' DB content is not supported
        [ "$database" = "information_schema" ] && continue
        # skip these MySQL built-in DBs too
        [ "$database" = "sys" ] && continue
        [ "$database" = "performance_schema" ] && continue
        timestamp "Exporting SQL instance '$sql_instance' database '$database'"
        # adding .gz will auto-encrypt the bucket
        gcloud sql export sql "$sql_instance" "gs://$gcs_bucket/backups/sql/$sql_instance--$database--$(date '+%F_%H%M').sql.gz" --database "$database"  # --offload
    done
done
echo >&2
timestamp "Cloud SQL exports to GCS bucket '$gcs_bucket' completed"
