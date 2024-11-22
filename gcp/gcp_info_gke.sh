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
Lists GKE resources deployed in the current GCP Project

Lists in this order:

    - GKE Clusters
    - Kubernetes, for every GKE cluster:
      - cluster-info
      - master component statuses
      - nodes
      - namespaces
      - deployments, replicasets, replication controllers, statefulsets, daemonsets, horizontal pod autoscalers
      - storage classes, persistent volumes, persistent volume claims
      - service accounts, resource quotas, network policies, pod security policies
      - pods  # might be too volumous if you have high replica counts, so done last, comment if you're sure nobody has deployed pods outside deployments

Can optionally specify a project id using the first argument, otherwise uses currently configured project

$gcp_info_formatting_help
Does not apply to Kubernetes info
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


# GKE clusters
cat <<EOF
# ============================================================================ #
#                            G K E   C l u s t e r s
# ============================================================================ #

EOF

list_gke_clusters(){
    if is_service_enabled container.googleapis.com; then
        gcp_info "GKE clusters" gcloud container clusters list
        if ! gcloud container clusters list | grep -q .; then
            echo "No GKE clusters found, skipping listing GKE deployments and resources"
            return 0
        fi
    else
        echo "Google Kubernetes Engine API (container.googleapis.com) is not enabled, skipping..."
        return
    fi
    list_gke_deployments
}


# Kubernetes
list_gke_deployments(){
    cat <<EOF


# ============================================================================ #
#                         G K E   D e p l o y m e n t s
# ============================================================================ #
EOF
    gcloud container clusters list --format='value(name,zone)' |
    while read -r cluster zone; do
        cat <<EOF

    # ======================================================= #
    # GKE Cluster: $cluster
    # ======================================================= #

EOF
        gcloud container clusters get-credentials "$cluster" --zone "$zone"
        echo
        "$srcdir/../kubernetes/kubernetes_info.sh"
    done
}


list_gke_clusters
