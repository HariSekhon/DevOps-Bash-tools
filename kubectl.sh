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
Safe way of running kubectl against a specific Kubernetes context by using an isolated fixed config for the lifetime of this script

Avoids concurrency race conditions from other commands or scripts changing the kubectl context

Eg. running:

    kubectl config use-context 'gke_<project>_europe-west1-<cluster_name>'

in another script or window would cause a concurrency race condition bug where your kubectl commands would fire against the new cluster instead, leading to cross environment misconfigurations and outages in real world usage

For frequent more convenient usage you will want to shorten the CLI by copying this script to a local copy in each cluster's yaml config directory and hardcoding the CONTEXT variable

The kubectl context specified should already be configured in your primary kubectl config which is copied to an isolated config to fix it before running your kubectl actions

Could also use explicit kubectl switches --cluster / --context, but this is more convenient, especially when hardcoded for the local copy in each cluster's k8s yaml dir
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<kubectl_context> <kubectl_options>"

help_usage "$@"

# ============================================================
# REMOVE AND HARDCODE THIS SECTION FOR SHORTER CLI convenience
min_args 2 "$@"

# fixed to this kubectl context - thou shalt deploy to no other cluster context from this script

# HARDCODE THIS for frequent shorter CLI usage
CONTEXT="$1"

# REMOVE THIS IF HARDCODING
shift || :
# ============================================================

# protect against race conditions and guarantee we will only make changes to the right k8s cluster
kubeconfig="/tmp/.kube/config.${EUID:-$UID}.$$"
mkdir -pv "$(dirname "$kubeconfig")"
cp -f "${KUBECONFIG:-$HOME/.kube/config}" "$kubeconfig"
export KUBECONFIG="$kubeconfig"

kubectl config use-context "$CONTEXT"
echo

kubectl "$@"
