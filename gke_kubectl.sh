#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-11-03 14:24:44 +0000 (Tue, 03 Nov 2020)
#
#  https://github.com/HariSekhon/bash-tools
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

# shellcheck disable=SC1090
. "$srcdir/lib/utils.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Runs a kubectl command safely fixed to a GKE cluster by generating an isolated fixed config for the lifetime of this script

Avoids concurrency race conditions with other concurrently executing commands or scripts by avoiding using or changing the global kubectl context

Eg. running:

    kubectl config use-context
            or
    gcloud container clusters get-credentials

either by your hand or in other concurrently executing scripts changes your global kubectl context to run on the given cluster, which could divert your command or concurrently long running scripts in other windows to run kubectl commands on the wrong cluster, leading to cross environment misconfigurations and real world outages (I've seen this personally)


For frequent more convenient usage you will want to shorten the CLI by copying this script to a local copy in each cluster's yaml config directory and hardcoding the PROJECT, CLUSTER and ZONE variables

Could also use main kube config with kubectl switches --cluster / --context (after configuring, see gke_kube_creds.sh), but this is more convenient, especially when hardcoded for the local copy in each cluster's k8s yaml dir


See Also:

    gke_kube_creds.sh - auto-populates the credentials for all GKE clusters for your kubectl is ready to rock on GCP
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<project> <cluster> <zone> <kubectl_options>"

help_usage "$@"

# ============================================================
# HARDCODE THIS SECTION FOR SHORTER CLI convenience
# REMOVE if hardcoding
min_args 4 "$@"

# fixed to this environment - thou shalt deploy to no other cluster from this script

# HARDCODE THESE for frequent shorter CLI usage
PROJECT="$1"  # used explicitly for easier tracking/debugging rather relying on implicit GOOGLE_PROJECT_ID which might not be what we expect
CLUSTER="$2"  # eg. <myproject>-europe-west1
ZONE="$3"     # eg. europe-west1

# REMOVE if hardcoding
shift || :
shift || :
shift || :
# ============================================================

# protect against race conditions and guarantee we will only make changes to the right k8s cluster
export KUBECONFIG="/tmp/.kube/config.${EUID:-$UID}.$$"

mkdir -pv "$(dirname "$KUBECONFIG")"

gcloud container clusters get-credentials "$CLUSTER" --zone "$ZONE" --project "$PROJECT"
echo >&2

kubectl "$@"
