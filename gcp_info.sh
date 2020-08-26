#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-08-13 19:38:39 +0100 (Thu, 13 Aug 2020)
#
#  https://github.com/harisekhon/bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/harisekhon
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

# shellcheck disable=SC1090
. "$srcdir/lib/utils.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Lists GCP deployed resources in the current or specified GCP Project

Make sure that you run this from an authorized network so things like kubectl don't hang

Lists in this order:

    - GCloud SDK version
    - Organizations
    - Auth, Configurations and Current Config Properties
    - Project ID
    - Services & APIs enabled
    - Service Accounts
    - GCE Virtual Machines
    - Cloud SQL instances
    - App Engine instances
    - Cloud Functions
    - Networks, Addresses, Subnets, Proxies, Reservations, Routers, VPNs, Tunnels, Routes
    - Firewall Rules & Forwarding Rules
    - DNS managed zones & verified domains
    - Cloud Storage Buckets
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
    - Dataflow jobs
    - PubSub topics
    - BigTable clusters and instances
    - Datastore Indexes

Can optionally specify a project id to switch to and list info for (will switch back to original project on any exit except kill -9)
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<project_id>]"

help_usage "$@"

#min_args 1 "$@"

check_bin gcloud

if [ $# -gt 0 ]; then
    project_id="$1"
    shift || :
    current_project="$(gcloud config list --format="value(core.project)")"
    if [ -n "$current_project" ]; then
        # want interpolation now not at exit
        # shellcheck disable=SC2064
        trap "gcloud config set project '$current_project'" EXIT
    else
        trap "gcloud config unset project" EXIT
    fi
    gcloud config set project "$project_id"
fi


# GCloud SDK tools versions
cat <<EOF
# ============================================================================ #
#                              G C l o u d   S D K
# ============================================================================ #

EOF

gcloud version

echo

#gsutil version -l

#echo

#bq version


# Organizations
cat <<EOF

# ============================================================================ #
#                           O r g a n i z a t i o n s
# ============================================================================ #

EOF

gcloud organizations list


# Auth & Config
cat <<EOF


# ============================================================================ #
#                           A u t h   &   C o n f i g
# ============================================================================ #

EOF

gcloud config configurations list
echo

# list credentialed accounts and show which one is active - dupliates info from configurations so not needed
#gcloud auth list
#echo

gcloud config list


# Project
cat <<EOF


# ============================================================================ #
#                                P r o j e c t s
# ============================================================================ #

EOF

echo "Projects:"
gcloud projects list
echo
echo "Checking project is configured..."
# unreliable only errors when not initially set, but gives (unset) if you were to 'gcloud config unset project'
#if ! gcloud config get-value project &>/dev/null; then
# ok, but ugly and format dependent
#if ! gcloud config list | grep '^project[[:space:]]='; then
# best
if ! gcloud info --format="get(config.project)" | grep -q .; then
    cat <<EOF

ERROR: You need to configure your Google Cloud project first

Select one from the project IDs above:

gcloud config set project <id>
EOF
    exit 1
fi


# Services & APIs Enabled
cat <<EOF

LISTING INFO FOR PROJECT:  $(gcloud info --format="get(config.project)")


# ============================================================================ #
#                 S e r v i c e s   &   A P I s   E n a b l e d
# ============================================================================ #

EOF

echo "getting list of all services & APIs (will use this to determine which services to list based on what is enabled)"
# Don't change order of headings here as is_services_enabled() below depends on this
services_list="$(gcloud services list --available --format "table[no-heading](state, config.name, config.title)")"
echo

is_service_enabled(){
    # must be the api path, eg. file.googleapis.com
    local service="$1"
    service="${service//./\.}"  # escape dots for grep
    grep -Ei "^ENABLED[[:space:]]+$service" <<< "$services_list"
}

echo "Services Enabled:"
echo
gcloud services list --enabled


# Secrets
cat <<EOF


# ============================================================================ #
#                                 S e c r e t s
# ============================================================================ #

EOF

gcloud secrets list


# Service Accounts
cat <<EOF


# ============================================================================ #
#                        S e r v i c e   A c c o u n t s
# ============================================================================ #

EOF

gcloud iam service-accounts list


# GCE Virtual Machines
cat <<EOF


# ============================================================================ #
#                        V i r t u a l   M a c h i n e s
# ============================================================================ #

EOF

#gcloud compute machine-types list

gcloud compute instances list --sort-by=ZONE


# Cloud SQL instances
cat <<EOF


# ============================================================================ #
#                     C l o u d   S Q L   I n s t a n c e s
# ============================================================================ #

EOF

gcloud sql instances list


# App instances
cat <<EOF


# ============================================================================ #
#                           A p p   I n s t a n c e s
# ============================================================================ #

EOF

gcloud app instances list


# Cloud Functions
cat <<EOF


# ============================================================================ #
#                         C l o u d   F u n c t i o n s
# ============================================================================ #

EOF

gcloud functions list


# Networking
cat <<EOF


# ============================================================================ #
#                              N e t w o r k i n g
# ============================================================================ #

EOF

echo "Networks:"
gcloud compute networks list
echo
echo "Addresses:"
gcloud compute addresses list
echo
echo "HTTP Proxies:"
gcloud compute target-http-proxies list
echo
echo "HTTPS Proxies:"
gcloud compute target-https-proxies list
echo
echo "SSL Proxies:"
gcloud compute target-ssl-proxies list
echo
echo "TCP Proxies:"
gcloud compute target-tcp-proxies list
echo
echo "URL Maps:"
gcloud compute url-maps list
echo
echo "Subnets:"
gcloud compute networks subnets list --sort-by=NETWORK
echo
echo "Routers:"
gcloud compute routers list
echo
echo "VPN Gateways:"
gcloud compute vpn-gateways list
echo
echo "VPN Tunnels:"
gcloud compute vpn-tunnels list
echo
echo "Reservations:"
gcloud compute reservations list
echo
echo "Routes:"
gcloud compute routes list


# Firewalls
cat <<EOF


# ============================================================================ #
#                               F i r e w a l l s
# ============================================================================ #

EOF

echo "Firewall Rules:"
gcloud compute firewall-rules list
# same output
#gcloud compute firewall-rules list --sort-by=NETWORK
echo
echo "Forwarding Rules:"
gcloud compute forwarding-rules list

# DNS
cat <<EOF


# ============================================================================ #
#                                     D N S
# ============================================================================ #

EOF

gcloud dns managed-zones list
echo
gcloud domains list-user-verified


# Cloud Storage Buckets
cat <<EOF


# ============================================================================ #
#                                 B u c k e t s
# ============================================================================ #

EOF

gsutil ls


# Cloud Filestore
cat <<EOF


# ============================================================================ #
#                         C l o u d   F i l e s t o r e
# ============================================================================ #

EOF

if is_service_enabled file.googleapis.com; then
    gcloud filestore instances list
else
    echo "Cloud Filestore API not enabled, skipping..."
fi


# TODO: prompts to set up - determine if set up before calling
# Cloud Run
#cat <<EOF


# ============================================================================ #
#                               C l o u d   R u n
# ============================================================================ #

#EOF

#gcloud run services list


# GKE clusters
cat <<EOF


# ============================================================================ #
#                            G K E   C l u s t e r s
# ============================================================================ #

EOF

gcloud container clusters list


# Kubernetes
cat <<EOF


# ============================================================================ #
#                         G K E   D e p l o y m e n t s
# ============================================================================ #
EOF

while read -r cluster zone; do
    cat <<EOF

    # ======================================================= #
    # GKE Cluster: $cluster
    # ======================================================= #

EOF
    gcloud container clusters get-credentials "$cluster" --zone "$zone"
    echo
    "$srcdir/kubernetes_info.sh"
done < <(gcloud container clusters list --format='value(name,zone)')


# Dataproc clusters
cat <<EOF


# ============================================================================ #
#                       D a t a p r o c   C l u s t e r s
# ============================================================================ #

EOF

if is_service_enabled dataproc.googleapis.com; then
    gcloud dataproc clusters list --region all
else
    echo "Dataproc service API not enabled, skipping..."
fi


# Dataflow jobs
cat <<EOF


# ============================================================================ #
#                           D a t a f l o w   J o b s
# ============================================================================ #

EOF

# this works even when set to DISABLED
#if is_service_enabled dataflow.googleapis.com; then
gcloud dataflow jobs list --region=all


# Cloud MemoryStore Redis
cat <<EOF

# ============================================================================ #
#                 C l o u d   M e m o r y s t o r e   R e d i s
# ============================================================================ #

EOF

if is_service_enabled redis.googleapis.com; then
    gcloud redis instances list --region all
else
    echo "Cloud Memorystore Redis API is not enabled, skipping..."
fi


# PubSub topics
cat <<EOF


# ============================================================================ #
#                           P u b S u b   T o p i c s
# ============================================================================ #

EOF

if is_service_enabled pubsub.googleapis.com; then
    gcloud pubsub topics list
else
    echo "Cloud PubSub API is not enabled, skipping..."
fi


# BigTable clusters and instances
cat <<EOF


# ============================================================================ #
#                                B i g T a b l e
# ============================================================================ #

EOF

# these work even though bigtable.googleapis.com is DISABLED
# if is_service_enabled bigtable.googleapis.com; then
echo "Clusters:"
gcloud bigtable clusters list
echo
echo "Instances:"
gcloud bigtable instances list


# Datastore Indexes
cat <<EOF


# ============================================================================ #
#                       D a t a s t o r e   I n d e x e s
# ============================================================================ #

EOF

if is_service_enabled datastore.googleapis.com; then
    gcloud datastore indexes list
else
    echo "Datastore API is not enabled, skipping..."
fi


# Source Repos
cat <<EOF


# ============================================================================ #
#                            S o u r c e   R e p o s
# ============================================================================ #

EOF

if is_service_enabled sourcerepo.googleapis.com; then
    gcloud source repos list
else
    echo "Source Repos API (sourcerepo.googleapis.com) is not enabled, skipping..."
fi


# Cloud Builds
cat <<EOF


# ============================================================================ #
#                            C l o u d   B u i l d s
# ============================================================================ #

EOF

if is_service_enabled cloudbuild.googleapis.com; then
    gcloud builds list
else
    echo "Cloud Builds API (cloudbuild.googleapis.com) is not enabled, skipping..."
fi


# Deployment Manager
cat <<EOF


# ============================================================================ #
#                      D e p l o y m e n t   M a n a g e r
# ============================================================================ #

EOF

if is_service_enabled deploymentmanager.googleapis.com; then
    gcloud deployment-manager deployments list
else
    echo "Deployment Manager API (deploymentmanager.googleapis.com) is not enabled, skipping..."
fi


# Finished
cat <<EOF


# ============================================================================ #
# Finished listing resources for GCP Project $(gcloud config list --format="value(core.project)")
# ============================================================================ #

EOF
