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

# https://cloud.google.com/sql/docs/postgres/backup-recovery/pitr#gcloud

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck disable=SC1090,SC1091
. "$srcdir/lib/utils.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Enable Cloud SQL point-in-time recovery

SQL instances can optionally be specified, otherwise iterates all running non-replica SQL instances

This automatically creates a backup at the time of enabling, which takes a few minutes during which your database may be unavailable.

WARNING: Enabling/Disabling point-in-time recovery restarts the instance, causing an outage, so this script will prompt for confirmation before proceeding.

Requires automated backups to already be enabled, otherwise you'll get this error:

    ERROR: (gcloud.sql.instances.patch) HTTPError 400: Invalid request: Point in time recovery must be disabled when backup is disabled.

See adjacent script to enable automated backups first:

    gcp_sql_enable_automated_backups.sh
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<sql_instance1> <sql_instance2> ...]"

help_usage "$@"

no_more_opts "$@"

sql_instances="$*"

if [ -z "$sql_instances" ]; then
    # XXX: backups cannot be run for read replicas, and nor can this be enabled for stopped instances which would result in:
    # ERROR: (gcloud.sql.instances.patch) HTTPError 400: The incoming request contained invalid data.
    sql_instances="$(gcloud sql instances list --format=json |
                     jq -r '.[] | select(.instanceType != "READ_REPLICA_INSTANCE") | select(.state == "RUNNABLE") | .name')"
fi

echo "Cloud SQL instances on which point-in-time recovery will be enabled:"
echo
for sql_instance in $sql_instances; do
    echo "$sql_instance"
done
echo
echo
echo "WARNING: Enabling or disabling point-in-time recovery restarts the instance, causing an outage"
echo
echo "WARNING: Do not do this on production databases during business hours"
echo
read -r -p "Are you sure you want to proceed to enable point-in-time recovery including restarting the above Cloud SQL instances? (y/N) " answer
echo
if ! [[ "$answer" =~ ^(y|yes)$ ]]; then
    echo "Aborting..."
    exit 1
fi

for sql_instance in $sql_instances; do
    timestamp "Enabling point-in-time recovery for SQL instance '$sql_instance':"
    gcloud sql instances patch "$sql_instance" --enable-point-in-time-recovery
    echo >&2
done
timestamp "Cloud SQL instances point-in-time recovery enabled"
