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
Lists GCP Big Data resources deployed in the current GCP Project

Lists in this order:

    - Dataproc clusters       (all regions)
    - Dataproc jobs           (all regions)
    - Dataflow jobs           (all regions)
    - PubSub topics
    - Cloud IOT registries    (all regions)

Environment variables of regions to shortcut scanning all regions, comma or space separated:

GCE_REGIONS - for Dataproc clusters and jobs
IOT_REGIONS - for Cloud IOT registries

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


# Dataproc clusters
cat <<EOF
# ============================================================================ #
#                       D a t a p r o c   C l u s t e r s
# ============================================================================ #

EOF

if is_service_enabled dataproc.googleapis.com; then
    # because --region=all doesn't work
    # inherit gce_regions if set elsewhere, eg. gcp_info_compute.sh called first when running gcp_info.sh
    gce_regions="${GCE_REGIONS:-${gce_regions:-$(gcloud compute regions list --format='table[no-heading](name)')}}"
    gce_regions="${gce_regions//,/ }"
    gcp_info "Dataproc clusters: global"      gcloud dataproc clusters list --region="global"
    for region in $gce_regions; do
        gcp_info "Dataproc clusters: $region" gcloud dataproc clusters list --region="$region"
    done
else
    echo "Dataproc API (dataproc.googleapis.com) is not enabled, skipping..."
fi


# Dataproc jobs
cat <<EOF


# ============================================================================ #
#                           D a t a p r o c   J o b s
# ============================================================================ #

EOF

if is_service_enabled dataproc.googleapis.com; then
    # because --region=all doesn't work
    # re-use gce_regions from above
    gcp_info "Dataproc jobs: global"          gcloud dataproc jobs list --region="global"
    for region in $gce_regions; do
        gcp_info "Dataproc jobs: $region"     gcloud dataproc jobs list --region="$region"
    done
else
    echo "Dataproc API (dataproc.googleapis.com) is not enabled, skipping..."
fi


# Dataflow jobs
cat <<EOF


# ============================================================================ #
#                           D a t a f l o w   J o b s
# ============================================================================ #

EOF

# works even when set to disabled:
#
# DISABLED  dataflow.googleapis.com   Dataflow API
#
#if is_service_enabled dataflow.googleapis.com; then
    # --region=all      actually works here unlike dataproc and cloud iot
    # --status=active   to see only running jobs
    gcp_info "Dataflow jobs" gcloud dataflow jobs list --region=all --status=all
#else
#    echo "Dataflow API (dataflow.googleapis.com) is not enabled, skipping..."
#fi


# PubSub topics
cat <<EOF


# ============================================================================ #
#                           P u b S u b   T o p i c s
# ============================================================================ #

EOF

if is_service_enabled pubsub.googleapis.com; then
    gcp_info "Cloud PubSub topics" gcloud pubsub topics list
else
    echo "Cloud PubSub API (pubsub.googleapis.com) is not enabled, skipping..."
fi


# Cloud IOT
cat <<EOF


# ============================================================================ #
#                               C l o u d   I O T
# ============================================================================ #

EOF

#iot_supported_regions="
#asia-east1
#europe-west1
#us-central1
#"

# get dynamically in case they add a region
# ERROR: (gcloud.iot.registries.list) NOT_FOUND: The cloud region 'projects/$GOOGLE_PROJECT_ID/locations/all' (location 'all') isn't supported. Valid regions: {asia-east1,europe-west1,us-central1}
iot_regions="${IOT_REGIONS:-$(gcloud iot registries list --region="all" 2>&1 | sed 's/.*{//; s/}//; s/,/ /g' || :)}"
iot_regions="${iot_regions//,/ }"

if is_service_enabled cloudiot.googleapis.com; then
    for region in $iot_regions; do
        gcp_info "Cloud IOT registries: $region" gcloud iot registries list --region="$region"
    done
else
    echo "Cloud IOT API ( cloudiot.googleapis.com) is not enabled, skipping..."
fi
