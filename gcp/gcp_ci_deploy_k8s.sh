#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2021-03-02 18:58:40 +0000 (Tue, 02 Mar 2021)
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
. "$srcdir/lib/gcp_ci.sh"

# shellcheck disable=SC1090,SC1091
. "$srcdir/lib/kubernetes.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Runs a GCP CI/CD Deploy to GKE Kubernetes

Environment variables to set in the CI/CD system:

APP                     - name of your application
BUILD                   - should be automatically set to the Git hash on Jenkins or TeamCity
ENVIRONMENT             - dev/staging/production - corresponding to a local k8s/<environment> directory in the checkout
CLUSTER_NAME            - name of your GKE cluster
CLOUDSDK_CORE_PROJECT   - project ID of your GCP project
CLOUDSDK_COMPUTE_REGION - GCP region of your GKE cluster
GCP_SERVICEACCOUNT_KEY  - the contents of a credentials.json for a serviceaccount with permissions to run Google Cloud Build

Primarily written for Jenkins and TeamCity, but should work with minor alterations in other CI/CD tools (see lib/gcp_ci.sh which infers branch and build details)
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args=""

# BUILD is inferred from the Git commit that triggered the CI/CD system
# The rest of these should be set by the CI/CD system
check_env_defined "APP"
check_env_defined "BUILD"
check_env_defined "ENVIRONMENT"
check_env_defined "CLOUDSDK_CORE_PROJECT"
check_env_defined "CLOUDSDK_COMPUTE_REGION"
check_env_defined "GKE_CLUSTER"
check_env_defined "GCP_SERVICEACCOUNT_KEY"

help_usage "$@"

#min_args 1 "$@"

set -x

kube_config_isolate

printenv

# auto-infer CLOUDSDK_CORE_PROJECT if not set in environment
# requires a uniform predictable project naming convention that maps to Git branches, tune this function in lib/gcp_ci.sh
# won't override CLOUDSDK_CORE_PROJECT
#set_gcp_project

# auto-infer CLOUDSDK_COMPUTE_REGION if not set in environment
# put logic or default region in lib/gcp_ci.sh function
# won't override CLOUDSDK_COMPUTE_REGION
#set_gcp_compute_region europe-west1

# provide a credentials.json file argument to this function or provide it in a GCP_SERVICEACCOUNT_KEY environment variable via the CI/CD system
# necessary so you can log in to different projects and maintain IAM permissions isolation for safety
# do not use the same serviceaccount with permissions across projects, you can cross contaminate and make mistakes, deploy the wrong environment etc.
gcp_login

gke_login "$GKE_CLUSTER"

cd "k8s/$ENVIRONMENT"

replace_latest_with_build "$BUILD"

download_kustomize

kustomize_kubernetes_deploy "${K8_APP:-$APP}" "${K8_NAMESPACE:-$APP}"
