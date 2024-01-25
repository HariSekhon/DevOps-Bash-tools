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
Runs a kubectl command safely fixed to a specific Kubernetes context by using an isolated fixed config for the lifetime of this script

Avoids concurrency race conditions with other concurrently executing commands or scripts by avoiding using or changing the global kubectl context

Eg. running:

    kubectl config use-context '<name>'

either by your hand or in other concurrently executing scripts changes your global kubectl context to run on the given cluster, which could divert your command or concurrently long running scripts in other windows to run kubectl commands on the wrong cluster, leading to cross environment misconfigurations and real world outages (I've seen this personally)

For frequent more convenient usage you will want to shorten the CLI by copying this script to a local copy in each cluster's yaml config directory and hardcoding the CONTEXT variable

The kubectl context specified should already be configured in your primary kubectl config which is copied to an isolated config to fix it before running your kubectl actions

Could also use explicit kubectl switches --cluster / --context, but this is more convenient, especially when hardcoded for the local copy in each cluster's k8s yaml dir


See Also:

    - aws_kubectl.sh - similar to this script but also downloads the AWS EKS credential
    - gke_kubectl.sh - similar to this script but also downloads the GCP GKE credential
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

kube_config_isolate

# switch context if not already the current context (avoids repeating "switching context" output noise when this script it called iteratively in loop by other scripts)
kube_context "$CONTEXT"

kubectl "$@"
