#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-10-16 10:51:45 +0100 (Fri, 16 Oct 2020)
#
#  https://github.com/HariSekhon/DevOps-Python-tools
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
Creates Cloud Scheduler PubSub jobs to trigger Cloud SQL export jobs for every database
in every running non-replica Cloud SQL instance in the current project

SQL instances can optionally be specified, otherwise iterates all running non-replica SQL instances
(only running instances can export, otherwise will error out)
(only non-replicas should be exported, replicas will likely fail due to conflict with replication recovery)

Consider scheduling cron to be before / after the Automated Backups window and before the Google Maintenance Window for each instance

Optional environment variables and their defaults:

\$BUCKET                  \${project_id}-sql-backups
\$PUBSUB_TOPIC            cloud-sql-backups
\$CLOUD_SCHEDULER_CRON    0 2 * * *
\$TIMEZONE                Etc/UTC
\$CLOUD_SCHEDULER_REPLACE if set to any value will delete and recreate the Cloud Scheduler job (gcloud prompts before deleting each job)

Caveat: if the scheduler kicks off a subsequent database export on the same SQL instance, it will fail to launch if the previous one hasn't finished yet, so the \$CLOUD_SCHEDULER_CRON will increment the hour field for each successive database on the same SQL instance
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<sql_instance1> <sql_instance2> ...]"

help_usage "$@"

no_more_opts "$@"

project_id="$(gcloud config list --format="value(core.project)")"
not_blank "$project_id" || die "ERROR: GCloud SDK core.project property not set in config"

bucket="${BUCKET:-${project_id}-sql-backups}"
cron="${CLOUD_SCHEDULER_CRON:-0 2 * * *}"
topic="${PUBSUB_TOPIC:-cloud-sql-backups}"
timezone="${TIMEZONE:-Etc/UTC}"

sql_instances="$*"

if [ -z "$sql_instances" ]; then
    # XXX: can only list databases and export from running instances
    #      can only export from non-replicas (see gcp_sql_export.sh for details)
    timestamp "Getting all SQL instance in the current project"
    sql_instances="$(gcloud sql instances list --format=json |
                     jq -r '.[] | select(.instanceType != "READ_REPLICA_INSTANCE") | select(.state == "RUNNABLE") | .name')"
fi

for sql_instance in $sql_instances; do
    timestamp "Getting all databases on SQL instance '$sql_instance'"
    databases="$(gcloud sql databases list --instance="$sql_instance" --format='get(name)')"
    echo >&2
    instance_cron="$cron"
    for database in $databases; do
        # skip information schema, not allowed to dump this on MySQL, fails with:
        # ERROR: (gcloud.sql.export.sql) [ERROR_RDBMS] mysqldump: Dumping 'information_schema' DB content is not supported
        [ "$database" = "information_schema" ] && continue
        # skip these MySQL built-in DBs too
        [ "$database" = "sys" ] && continue
        [ "$database" = "performance_schema" ] && continue
        job_name="cloud-sql-backup--$sql_instance--$database"
        if [ -n "${CLOUD_SCHEDULER_REPLACE:-}" ]; then
            timestamp "Deleting Cloud Scheduler job for instance '$sql_instance' database '$database' if exists"
            gcloud scheduler jobs delete "$job_name" || :
            echo >&2
        fi
        timestamp "Creating Cloud Scheduler job for instance '$sql_instance' database '$database' with cron '$instance_cron'"
        gcloud scheduler jobs create pubsub "$job_name" --schedule "$instance_cron" --topic "$topic" --message-body '{ "database": "'"$database"'", "instance": "'"${sql_instance}"'", "project": "'"$project_id"'", "bucket": "'"$bucket"'" }' --time-zone "$timezone" --description "Triggers Cloud SQL export of instance '$sql_instance' database '$database' via a PubSub message trigger to a Cloud Function"
        echo >&2
        # increments the second hour field, resets the clock if we hit midnight
        instance_cron="$(awk '{if($2 > 22){$2 -= 24}; print $1" "$2+1" "$3" "$4" "$5}' <<< "$instance_cron")"
    done
done
