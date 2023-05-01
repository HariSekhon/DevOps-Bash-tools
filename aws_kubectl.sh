#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-12-11 10:56:52 +0000 (Fri, 11 Dec 2020)
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
. "$srcdir/lib/aws.sh"

# shellcheck disable=SC1090,SC1091
. "$srcdir/lib/kubernetes.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Runs a kubectl command safely fixed to an AWS EKS cluster by generating an isolated fixed config for the lifetime of this script

Avoids concurrency race conditions with other concurrently executing commands or scripts by avoiding using or changing the global kubectl context

Eg. running:

    kubectl config use-context
            or
    aws eks update-kubeconfig

either by your hand or in other concurrently executing scripts changes your global kubectl context to run on the given cluster, which could divert your command or concurrently long running scripts in other windows to run kubectl commands on the wrong cluster, leading to cross environment misconfigurations and real world outages (I've seen this personally)

For frequent more convenient usage you will want to shorten the CLI by copying this script to a local copy in each cluster's yaml config directory and hardcoding the CLUSTER and REGION variables

Could also use main kube config with kubectl switches --cluster / --context (after configuring, see aws_kube_creds.sh), but this is more convenient, especially when hardcoded for the local copy in each cluster's k8s yaml dir


$usage_aws_cli_required
(kubectl is also installed as part of 'make aws')


See Also:

    aws_kube_creds.sh - auto-populates the credentials for all EKS clusters for your kubectl is ready to rock on AWS
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<cluster> <zone> <kubectl_options>"

help_usage "$@"


# ============================================================
# HARDCODE THIS SECTION FOR SHORTER CLI convenience
# REMOVE if hardcoding
min_args 3 "$@"

# fixed to this environment - thou shalt deploy to no other cluster from this script

# HARDCODE THESE for frequent shorter CLI usage
CLUSTER="$1"  # eg. my-cluster
REGION="$2"   # eg. us-east-1

# REMOVE if hardcoding
shift || :
shift || :
# ============================================================

kube_config_isolate

aws eks update-kubeconfig --name "$CLUSTER" --region "$REGION"
echo >&2

kubectl "$@"
