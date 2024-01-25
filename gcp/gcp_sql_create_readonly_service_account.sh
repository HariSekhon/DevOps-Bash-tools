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
Creates a GCP service account in the current project called \${GOOGLE_SERVICE_ACCOUNT}@\${project_id}.iam.gserviceaccount.com

GOOGLE_SERVICE_ACCOUNT defaults to 'cloud-function-sql-backup'

Grants it permissions:

    - Cloud SQL Client
    - Cloud SQL Viewer


This is necessary to set up Cloud SQL export backups to GCS using the adjacent scripts. See

    gcp_cloud_schduler_sql_exports.sh

See the Cloud Function at:

    https://github.com/HariSekhon/DevOps-Python-tools


This script is idempotent and safe to re-run even if the service account already exists and has permissions
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args=""

help_usage "$@"

project="$(gcloud config list --format="value(core.project)")"
not_blank "$project" || die "ERROR: GCloud SDK core.project property not set"
name="${GOOGLE_SERVICE_ACCOUNT:-cloud-function-sql-backup}"
service_account="$name@$project.iam.gserviceaccount.com"

if ! gcloud iam service-accounts list | grep -q "$service_account"; then
    timestamp "Creating GCP service account '$service_account'"
    gcloud iam service-accounts create "$name" --description "Exports Cloud SQL data to GCS"
    echo >&2
fi

timestamp "Granting CloudSQL Client to service account '$service_account'"
gcloud projects add-iam-policy-binding "$project" --member="serviceAccount:$service_account" --role=roles/cloudsql.client
echo >&2

timestamp "Granting CloudSQL Client to service account '$service_account'"
gcloud projects add-iam-policy-binding "$project" --member="serviceAccount:$service_account" --role=roles/cloudsql.viewer
echo >&2

# XXX: need to grant the Cloud SQL instance service accounts objectCreator to the bucket, not this cloud function's service account
#      see instead adjacent script:
#
#      gcp_sql_grant_instances_gcs_object_creator.sh
#
#timestamp "Granting Storage Object Creator on bucket '$bucket' to service account '$service_account'"
#gsutil iam ch "serviceAccount:$service_account:objectCreator" "gs://$bucket"
