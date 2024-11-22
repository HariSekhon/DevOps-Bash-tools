#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-08-13 19:38:39 +0100 (Thu, 13 Aug 2020)
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

# shellcheck disable=SC1090,SC1091
. "$srcdir/lib/gcp.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Lists GCP storage resources deployed in the current GCP Project

Lists in this order:

    - Cloud SQL instances
    - Cloud SQL backups enabled
    - Cloud Storage Buckets
    - Cloud Filestore
    - Cloud Memorystore Redis
    - BigTable clusters and instances
    - Datastore Indexes

Can optionally specify a project id using the first argument, otherwise uses currently configured project

$gcp_info_formatting_help
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<project_id>]"

help_usage "$@"

max_args 1 "$@"

check_bin gcloud

if [ $# -gt 0 ]; then
    project_id="$1"
    shift || :
    export CLOUDSDK_CORE_PROJECT="$project_id"
fi


# shellcheck disable=SC1090,SC1091
type is_service_enabled &>/dev/null || . "$srcdir/gcp_service_apis.sh" >/dev/null

"$srcdir/gcp_info_cloud_sql.sh"

# Cloud Storage Buckets
cat <<EOF


# ============================================================================ #
#                                 B u c k e t s
# ============================================================================ #

EOF

if is_service_enabled storage-component.googleapis.com; then
    gsutil ls
else
    echo "Cloud Storage API (storage-component.googleapis.com) is not enabled, skipping..."
fi


# Cloud Filestore
cat <<EOF


# ============================================================================ #
#                         C l o u d   F i l e s t o r e
# ============================================================================ #

EOF

if is_service_enabled file.googleapis.com; then
    gcp_info "Cloud Filestore instances" gcloud filestore instances list
else
    echo "Cloud Filestore API (file.googleapis.com) is not enabled, skipping..."
fi


# Cloud MemoryStore Redis
cat <<EOF


# ============================================================================ #
#                 C l o u d   M e m o r y s t o r e   R e d i s
# ============================================================================ #

EOF

if is_service_enabled redis.googleapis.com; then
    gcp_info "Cloud Memorystore Redis instances" gcloud redis instances list --region all
else
    echo "Cloud Memorystore Redis API (redis.googleapis.com) is not enabled, skipping..."
fi


# BigTable clusters and instances
cat <<EOF


# ============================================================================ #
#                                B i g T a b l e
# ============================================================================ #

EOF

# works even with these disabled:
#
# DISABLED  bigtable.googleapis.com                               Cloud Bigtable API
# DISABLED  bigtableadmin.googleapis.com                          Cloud Bigtable Admin API
# DISABLED  bigtabletableadmin.googleapis.com                     Cloud Bigtable Table Admin API
#
# if is_service_enabled bigtable.googleapis.com; then
    gcp_info "BigTable clusters"  gcloud bigtable clusters list
    gcp_info "BigTable instances" gcloud bigtable instances list
#else
#    echo "BigTable API (bigtable.googleapis.com) is not enabled, skipping..."
#fi


# Datastore Indexes
cat <<EOF


# ============================================================================ #
#                       D a t a s t o r e   I n d e x e s
# ============================================================================ #

EOF

if is_service_enabled datastore.googleapis.com; then
    # may error out if doesn't exist
    gcp_info "Cloud Datastore indexes" gcloud datastore indexes list || :
else
    echo "Datastore API datastore.googleapis.com) is not enabled, skipping..."
fi
