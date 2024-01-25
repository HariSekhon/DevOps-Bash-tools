#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-10-16 12:01:31 +0100 (Fri, 16 Oct 2020)
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
Grants all running non-replica SQL database instances in the current project objectCreator access to a GCS bucket for backup exports

Can specify an explicit list to grant if wanting to grant to non-running instances or only a subset of instances

This is necessary to back up Cloud SQL to GCS using the adjacent scripts. See

    gcp_sql_export.sh
    gcp_cloud_scheduler_sql_exports.sh

See the Cloud Function at:

    https://github.com/HariSekhon/DevOps-Python-tools


This script is idempotent and safe to re-run
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

# Need to grant the Cloud SQL instance service accounts objectCreator to the bucket, not this cloud function account
#timestamp "Granting Storage Object Creator on bucket '$bucket' to service account '$service_account'"
#gsutil iam ch "serviceAccount:$service_account:objectCreator" "gs://$bucket"

for sql_instance in $sql_instances; do
    service_account="$(gcloud sql instances describe "$sql_instance" --format='get(serviceAccountEmailAddress)')"
    timestamp "Granting instance '$sql_instance' service account '$service_account' objectCreator role to the backup bucket '$gcs_bucket'"
    gsutil iam ch "serviceAccount:$service_account:objectCreator" "gs://$gcs_bucket"
    echo >&2
done
timestamp "Cloud SQL grants to GCS bucket '$gcs_bucket' completed"
