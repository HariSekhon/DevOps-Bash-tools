#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#  shellcheck disable=SC1090,SC1091
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

# Gather common GCP environment info for quickly surveying new client environments
#
# Requires:
#
# - GCloud CLI to be available and configured 'gcloud init'
#   (or just use Cloud Shell, will prompt you to set the project if it's not already)
# - API services to be enabled (or to select Y to enable them when prompted)
# - Billing to be enabled in order to enable API services
#
# Tested with Google Cloud SDK installed locally

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck disable=SC1090,SC1091
. "$srcdir/lib/utils.sh"

# shellcheck disable=SC1090,SC1091
. "$srcdir/lib/gcp.sh"

# shellcheck disable=SC2034,SC2154,SC1117
usage_description="
Lists GCP deployed resources in the current or specified GCP Project

Make sure that you run this from an authorized network so things like kubectl don't hang

Lists in this order (categories broadly reflect the GCP Console grouping of services):

    - GCloud SDK version
    - Auth, Organizations & Config:
      - Organizations
      - Auth Configurations
      - Current Configuration & Properties
    - Projects:
      - Project Names & IDs
      - Current Project
      - checks project is set to continue with the following
    - Services & APIs:
      - Enabled Services & API
      - collectors all available services to only show enabled services from this point onwards
    - Accounts & Secrets:
      - IAM Service Accounts
      - Secrets Manager secrets
    - Compute:
      - GCE Virtual Machines
      - App Engine instances
      - Cloud Functions
      - GKE Clusters
      - Kubernetes, for every GKE cluster:
        - cluster-info
        - master component statuses
        - nodes
        - namespaces
        - deployments, replicasets, replication controllers, statefulsets, daemonsets, horizontal pod autoscalers
        - services, ingresses
        - jobs, cronjobs
        - storage classes, persistent volumes, persistent volume claims
        - service accounts, resource quotas, network policies, pod security policies
        - container images running
        - container images running counts descending
        - pods  # might be too much detail if you have high replica counts, so done last, comment if you're sure nobody has deployed pods outside deployments
    - Storage:
      - Cloud SQL instances
      - Cloud SQL backups enabled
      - Cloud Storage Buckets
      - Cloud Filestore
      - Cloud Memorystore Redis
      - BigTable clusters and instances
      - Datastore Indexes
    - Networks:
      - VPC Networks
      - Addresses
      - Proxies
      - Subnets
      - Routers
      - Routes
      - VPN Gateways
      - VPN Tunnels
      - Reservations
      - Firewall Rules & Forwarding Rules
      - DNS managed zones & verified domains
    - Big Data:
      - Dataproc clusters       (all regions)
      - Dataproc jobs           (all regions)
      - Dataflow jobs           (all regions)
      - PubSub topics
      - Cloud IOT Registries    (all regions)
    - Tools:
      - Cloud Source Repositories
      - Cloud Builds
      - Container Registry Images
      - Deployment Manager

This is useful in so many ways. Aside from a general inventory / overview for a new client, you might be interested in tracking down a specific IP address by outputting this to a file and then running grepping for the IPs:

    ${0##*/} | tee output.txt && grep -E '[[:digit:]]+(\.[[:digit:]]+){3}' output.txt

$gcp_info_noninteractive_help

Can optionally specify a project id using the first argument, otherwise uses currently configured project

$gcp_info_formatting_help
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<project_id>]"

help_usage "$@"

check_bin gcloud

if [ $# -gt 0 ]; then
    project_id="$1"
    shift || :
    export CLOUDSDK_CORE_PROJECT="$project_id"
fi


# GCloud SDK tools versions
cat <<EOF
# ============================================================================ #
#                              G C l o u d   S D K
# ============================================================================ #

EOF

gcloud version
#echo
#gsutil version -l
#echo
#bq version
echo
echo

# ============================================================================ #
. "$srcdir/gcp_info_auth_config.sh"
echo
echo

# ============================================================================ #
. "$srcdir/gcp_info_projects.sh"
echo
echo

# ============================================================================ #
# this is done after gcp_info_projects.sh because that enforces having a project set
echo "LISTING INFO FOR PROJECT:  $(gcloud info --format="get(config.project)")"
echo
echo

# ============================================================================ #
. "$srcdir/gcp_info_services.sh"
echo
echo

# ============================================================================ #
. "$srcdir/gcp_info_accounts_secrets.sh"
echo
echo

# ============================================================================ #
. "$srcdir/gcp_info_compute.sh"
echo
echo

# ============================================================================ #
. "$srcdir/gcp_info_storage.sh"
echo
echo

# ============================================================================ #
. "$srcdir/gcp_info_networking.sh"
echo
echo

# ============================================================================ #
. "$srcdir/gcp_info_bigdata.sh"
echo
echo

# ============================================================================ #
. "$srcdir/gcp_info_tools.sh"
echo
echo

# Finished
cat <<EOF
# ============================================================================ #
# Finished listing resources for GCP Project $(gcloud config list --format="value(core.project)")
# ============================================================================ #
EOF
