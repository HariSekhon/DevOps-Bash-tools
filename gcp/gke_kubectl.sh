#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-11-03 14:24:44 +0000 (Tue, 03 Nov 2020)
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
. "$srcdir/lib/kubernetes.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Runs a kubectl command safely fixed to a GKE cluster by generating an isolated fixed config for the lifetime of this script

Avoids concurrency race conditions with other concurrently executing commands or scripts by avoiding using or changing the global kubectl context

Eg. running:

    kubectl config use-context
            or
    gcloud container clusters get-credentials

either by your hand or in other concurrently executing scripts changes your global kubectl context to run on the given cluster, which could divert your command or concurrently long running scripts in other windows to run kubectl commands on the wrong cluster, leading to cross environment misconfigurations and real world outages (I've seen this personally)

If GKE_CONTEXT is set in the environment and matches a pre-existing context, skips pulling GKE creds for speed and noise reduction.

If GKE_CONTEXT is not set then requires the following to be set in the environment in order to obtain the credentials to the GKE cluster (will try to auto-infer from gcloud config if not set):

CLOUDSDK_CORE_PROJECT       - project containing your GKE cluster
CLOUDSDK_COMPUTE_REGION     - region containing your GKE cluster
CLOUDSDK_CONTAINER_CLUSTER  - name of your GKE cluster

If the CLOUDSDK variables are not set and cannot be inferred from gcloud config, then errors out. If they are set though, they may be pointing to the wrong project or region so it is recommended to set them

For frequent more convenient usage you will want to shorten the CLI by copying this script to a local copy in each cluster's yaml config directory and hardcoding the GKE_CONTEXT (use gke_kube_creds.sh to pre-populate the context and credentials) or CLOUDSDK_CORE_PROJECT, CLOUDSDK_COMPUTE_REGION and CLOUDSDK_CONTAINER_CLUSTER variables if pulling GKE creds.

Could also use main kube config with kubectl switches --cluster / --context (after configuring, see gke_kube_creds.sh), but this is more convenient, especially when hardcoded for the local copy in each cluster's k8s yaml dir


See Also:

    gke_kube_creds.sh - auto-populates the credentials for all GKE clusters for your kubectl is ready to rock on GCP
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<kubectl_options>"

help_usage "$@"

min_args 1 "$@"

# ============================================================
# HARDCODE THIS SECTION FOR SHORTER CLI convenience
# REMOVE if hardcoding

#GKE_CONTEXT=gke_<myproject>_<myregion>_<clustername>

if [ -z "${GKE_CONTEXT:-}" ]; then

    # fixed to this environment - thou shalt deploy to no other cluster from this script

    # HARDCODE THESE for frequent shorter CLI usage
    #CLOUDSDK_CORE_PROJECT=myproject
    #CLOUDSDK_COMPUTE_REGION=europe-west1
    #CLOUDSDK_CONTAINER_CLUSTER="$2"  # eg. <myproject>-europe-west1

    CLOUDSDK_CORE_PROJECT="${CLOUDSDK_CORE_PROJECT:-$(gcloud config list --format="get(core.project)")}"
    CLOUDSDK_COMPUTE_REGION="${CLOUDSDK_COMPUTE_REGION:-$(gcloud config list --format="get(compute.region)")}"
    CLOUDSDK_CONTAINER_CLUSTER="${CLOUDSDK_CONTAINER_CLUSTER:-$(gcloud config list --format="get(container.cluster)")}"
    check_env_defined CLOUDSDK_CORE_PROJECT
    check_env_defined CLOUDSDK_COMPUTE_REGION
    check_env_defined CLOUDSDK_CONTAINER_CLUSTER

    # if set and available in original kube config, will just copy config and switch to this context (faster and less noisy than re-pulling creds from GKE)
    GKE_CONTEXT="gke_${CLOUDSDK_CORE_PROJECT}_${CLOUDSDK_COMPUTE_REGION}_${CLOUDSDK_CONTAINER_CLUSTER}"
fi
# ============================================================

kube_config_isolate

if ! gcloud auth application-default print-access-token >/dev/null; then
    gcloud auth application-default login
fi

# if original kube config contains the context, copy and reuse it (faster and less noisy than re-pulling the creds from GKE), especially when called in script iterations
if [ -n "${GKE_CONTEXT:-}" ] &&
   kubectl config get-contexts -o name | grep -Fxq "$GKE_CONTEXT"; then
    # switch context if not already the current context (avoids repeating "switching context" output noise when this script it called iteratively in loop by other scripts)
    if [ "$(kubectl config current-context)" != "$GKE_CONTEXT" ]; then
        kubectl config use-context "$GKE_CONTEXT" >&2
    fi
else
    gcloud container clusters get-credentials "$CLOUDSDK_CONTAINER_CLUSTER" --region "$CLOUDSDK_COMPUTE_REGION" --project "$CLOUDSDK_CORE_PROJECT" >&2
    echo >&2
fi

kubectl "$@"
